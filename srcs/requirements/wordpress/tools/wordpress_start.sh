#!/bin/bash

set -e

WP_PATH="/var/www/wordpress"

MYSQL_PASSWORD=$(cat /run/secrets/db_password | tr -d '\n')
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password | tr -d '\n')
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password | tr -d '\n')

if [ ! -f "${WP_PATH}/wp-config.php" ]; then

    echo "[WordPress] Kurulum başlıyor..."

    mkdir -p "${WP_PATH}"

    wp core download \
        --path="${WP_PATH}" \
        --locale=en_US \
        --allow-root

    wp config create \
        --path="${WP_PATH}" \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost=mariadb \
        --allow-root

    wp core install \
        --path="${WP_PATH}" \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    wp user create \
        --path="${WP_PATH}" \
        "${WP_USER}" "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author \
        --allow-root

    echo "[WordPress] Kurulum tamamlandı."
fi

    chown -R www-data:www-data $WP_PATH
    chmod -R 755 $WP_PATH

exec php-fpm8.2 -F
