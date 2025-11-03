# 🐬 MySQL 4.0.27 Docker Image (i386 / Debian Buster Slim)

This repository provides a **Dockerized build of MySQL 4.0.27**, running on a 32-bit Debian Buster base (`i386/debian:buster-slim`).

This is mainly intended for **legacy software compatibility**, such as old PHP 4/5 applications or systems that require the MySQL 4.x protocol.

---

## ⚙️ Features

- ✅ Based on `i386/debian:buster-slim`
- ✅ Ships with official `mysql-standard-4.0.27-pc-linux-gnu-i686.tar.gz`
- ✅ Minimal dependencies
- ✅ Custom entrypoint to auto-initialize data directory
- ✅ Supports `MYSQL_ROOT_PASSWORD` environment variable
- ✅ Compatible with legacy clients / libraries

---

## 📁 Directory Layout
├── `Dockerfile` <br>
├── `docker-entrypoint.sh` <br>
├── `my.cnf` <br>
└── `mysql-standard-4.0.27-pc-linux-gnu-i686.tar.gz` <br>

---

## 🚀 Quick Start

### 1️⃣ Clone the repository

```bash
git clone https://github.com/mrizkihidayat66/mysql-4.0.27-docker.git
cd mysql-4.0.27-docker
```

### 2️⃣ Build the Docker image

```bash
docker build --platform=linux/386 -t mysql:4.0.27 .
```

### 3️⃣ Create a data volume

```bash
docker volume create mysql4_data
```

### 4️⃣ Run the container

```bash
docker run -d --name mysql4 -e MYSQL_ROOT_PASSWORD=YOUR_ROOT_PASSWORD -v mysql4_data:/var/lib/mysql -p 3306:3306 --platform=linux/386 mysql:4.0.27
```

✅ This will:
- initialize the MySQL data directory (if empty)
- set the root password to `YOUR_ROOT_PASSWORD`
- expose MySQL 4.0.27 on port 3306

### 5️⃣ Check logs

```bash
docker logs -f mysql4
```

### 6️⃣ Connect to MySQL 4.0.27

From host (if you have a modern MySQL client):

```bash
mysql -h 127.0.0.1 -P 3306 -u root -p
```

Or from inside the container:

```bash
docker exec -it mysql4 bash
/usr/local/mysql/bin/mysql -u root -p
```

---

### 🧱 Stopping and Restarting

Start:

```bash
docker stop mysql4
```

Stop:

```bash
docker start mysql4
```

---

### 🗑️ Remove Everything

```bash
docker stop mysql4
docker rm mysql4
docker volume rm mysql4_data
docker rmi mysql4:4.0.27
```

---

### ⚠️ Notes & Compatibility

- This image is **32-bit only** (`i386`), due to the MySQL 4.0.27 binary build.
- Not suitable for production use — intended for **legacy maintenance** only.
- Uses MyISAM and early InnoDB; does not support modern features like triggers, views, or UTF-8MB4.
- Tested working on:
  - Docker 25.0+
  - Debian 12 (host)
  - Windows 10/11 with WSL2

---

### 🕰️ License

This image redistributes the **MySQL 4.0.27 Standard Edition binaries**, which were originally released under the **GPL v2** by MySQL AB (2006).

See: https://downloads.mysql.com/archives/

---

**Enjoy your retro MySQL setup 🧡 — perfect for restoring vintage LAMP stacks!**
