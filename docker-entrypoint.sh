#!/bin/bash
set -euo pipefail

MYSQL_BASE=${MYSQL_BASE:-/usr/local/mysql}
MYSQL_DATADIR=${MYSQL_DATADIR:-/var/lib/mysql}
MYSQL_USER=${MYSQL_USER:-mysql}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-}

# path to server and helper scripts
MYSQLD="$MYSQL_BASE/bin/mysqld"
MYSQL_SAFE="$MYSQL_BASE/bin/mysqld_safe"
MYSQL_INSTALL_DB="$MYSQL_BASE/scripts/mysql_install_db"
MYSQLADMIN="$MYSQL_BASE/bin/mysqladmin"
MYSQL_CLIENT="$MYSQL_BASE/bin/mysql"

# sanity checks
if [ ! -x "$MYSQLD" ]; then
  echo "ERROR: mysqld binary not found at $MYSQLD"
  ls -la "$MYSQL_BASE" || true
  exit 1
fi

# ensure datadir exists & owned
mkdir -p "$MYSQL_DATADIR"
chown -R "$MYSQL_USER":"$MYSQL_USER" "$MYSQL_DATADIR"

# Initialize DB if empty
if [ -z "$(ls -A "$MYSQL_DATADIR" 2>/dev/null || true)" ]; then
  echo ">>> Initializing MySQL 4.0 data directory: $MYSQL_DATADIR"

  if [ -x "$MYSQL_INSTALL_DB" ]; then
    echo ">>> Running mysql_install_db..."
    chown -R "$MYSQL_USER":"$MYSQL_USER" "$MYSQL_BASE"
    # run as the mysql user
    su -s /bin/bash -c "$MYSQL_INSTALL_DB --datadir=$MYSQL_DATADIR --basedir=$MYSQL_BASE --user=$MYSQL_USER" "$MYSQL_USER"
  else
    echo "WARNING: mysql_install_db not found. Attempting fallback initialization."
    # Attempt a very basic fallback: run server once to create files
    "$MYSQLD" --datadir="$MYSQL_DATADIR" --basedir="$MYSQL_BASE" --user="$MYSQL_USER" --skip-networking --skip-grant-tables &
    pid="$!"
    sleep 3
    kill "$pid" || true
  fi

  # start a temporary server (without networking) to set root password
  mkdir -p /var/run/mysqld
  chown -R "$MYSQL_USER":"$MYSQL_USER" /var/run/mysqld
  echo ">>> Starting temporary server to set root password..."
  "$MYSQLD" --datadir="$MYSQL_DATADIR" --basedir="$MYSQL_BASE" --user="$MYSQL_USER" --skip-networking --skip-grant-tables &
  tmp_pid="$!"

  # wait for server socket/file to appear
  sleep 2
  for i in $(seq 1 20); do
    if pgrep -f "mysqld" >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done

  # If a password is provided, set it; otherwise leave blank but warn
  if [ -n "$MYSQL_ROOT_PASSWORD" ]; then
    echo ">>> Setting root password and enabling remote root access..."
    SQL="UPDATE mysql.user SET Password=PASSWORD(\"$MYSQL_ROOT_PASSWORD\") WHERE User='root';
DELETE FROM mysql.user WHERE Host='%' AND User='root';
INSERT INTO mysql.user (Host,User,Password,
  Select_priv,Insert_priv,Update_priv,Delete_priv,Create_priv,Drop_priv,Reload_priv,Shutdown_priv,Process_priv,
  File_priv,Grant_priv,References_priv,Index_priv,Alter_priv)
VALUES ('%','root',PASSWORD(\"$MYSQL_ROOT_PASSWORD\"),
  'Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y');"
    echo "$SQL" | "$MYSQL_CLIENT" || true
    echo "FLUSH PRIVILEGES;" | "$MYSQL_CLIENT" || true
  else
    echo ">>> WARNING: MYSQL_ROOT_PASSWORD not set — root will have empty password (insecure)."
  fi

  # stop temporary server
  kill "$tmp_pid" || true
  sleep 1
fi

# Clean up any previous mysqld processes that might still be running
echo ">>> Cleaning up old mysqld instances..."
pkill -9 mysqld || true
sleep 1

# finally, exec mysqld_safe (keeps running in foreground in many old versions)
echo ">>> Starting mysqld_safe..."
exec "$MYSQL_SAFE" --datadir="$MYSQL_DATADIR" --basedir="$MYSQL_BASE" --user="$MYSQL_USER"
