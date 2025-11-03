FROM i386/debian:buster-slim

ENV MYSQL_BASE=/usr/local/mysql \
    MYSQL_DATADIR=/var/lib/mysql \
    MYSQL_USER=mysql \
    PATH=/usr/local/mysql/bin:$PATH

RUN sed -i 's|deb.debian.org|archive.debian.org|g' /etc/apt/sources.list && \
    sed -i '/security.debian.org/d' /etc/apt/sources.list && \
    echo "Acquire::Check-Valid-Until false;" > /etc/apt/apt.conf.d/99no-check-valid

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates libaio1 libncurses5 procps tzdata gosu tar \
  && rm -rf /var/lib/apt/lists/*

RUN groupadd -r $MYSQL_USER || true \
 && useradd -r -g $MYSQL_USER -s /usr/sbin/nologin -d $MYSQL_DATADIR $MYSQL_USER || true

# Extract directly into /usr/local/mysql (expected path)
COPY mysql-standard-4.0.27-pc-linux-gnu-i686.tar.gz /tmp/
RUN mkdir -p /usr/local/mysql \
 && tar -xzf /tmp/mysql-standard-4.0.27-pc-linux-gnu-i686.tar.gz -C /usr/local/ \
 && mv /usr/local/mysql-standard-4.0.27-pc-linux-gnu-i686/* /usr/local/mysql/ \
 && rm -rf /tmp/mysql-standard-4.0.27-pc-linux-gnu-i686*

COPY my.cnf /etc/my.cnf
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

RUN mkdir -p $MYSQL_DATADIR /usr/local/mysql/logs /var/run/mysqld \
 && chown -R $MYSQL_USER:$MYSQL_USER $MYSQL_DATADIR /usr/local/mysql /var/run/mysqld

VOLUME ["${MYSQL_DATADIR}"]

EXPOSE 3306
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["mysqld_safe"]
