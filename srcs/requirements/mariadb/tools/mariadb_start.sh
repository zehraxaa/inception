#!/bin/bash

set -e #scriptin herhangi bir komutu hata verirse devam etmez

# MYSQL_PASSWORD=$(cat /run/secrets/db_password)
# MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password) 

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

if [ ! -d "/var/lib/mysql/mysql" ]; then

    mariadb_install_db --user=mysql --datadir=/var/lib/mysql
    service mariadb start

    mariadb --user root << EOF
    CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
    CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
    GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
    FLUSH PRIVILEGES;
EOF
    mysqladmin --user=root --password="${MYSQL_ROOT_PASSWORD}" shutdown
fi
    exec mariadbd --user=mysql
