#!/bin/bash

# Herhangi bir komut hata verirse script durur
set -e

WP_PATH="/var/www/wordpress"

# ──────────────────────────────────────────────
# 1. ADIM: Docker Secrets'ten şifreyi oku
# ──────────────────────────────────────────────
MYSQL_PASSWORD=$(cat /run/secrets/db_password | tr -d '\n')
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password | tr -d '\n')
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password | tr -d '\n')

# ──────────────────────────────────────────────
# 2. ADIM: WordPress dosyalarını kur (daha önce kurulmadıysa)
# ──────────────────────────────────────────────
# wp-config.php varlığını kontrol et — bu dosya hem download hem install
# adımından SONRA oluşur, dolayısıyla güvenilir bir "kurulum bitti" göstergesidir.
# "wp core is-installed" ise DB bağlantısı gerektirir, daha kırılgan olur.
if [ ! -f "${WP_PATH}/wp-config.php" ]; then

    echo "[WordPress] Kurulum başlıyor..."

    # Dizin yoksa oluştur
    mkdir -p "${WP_PATH}"

    # WordPress çekirdek dosyalarını indir
    # --skip-content: themes/plugins indirmez, çok daha hızlı
    wp core download \
        --path="${WP_PATH}" \
        --locale=en_US \
        --skip-content \
        --allow-root

    # wp-config.php oluştur (veritabanı bağlantı bilgileri)
    # dbhost = docker-compose'daki servis adı
    wp config create \
        --path="${WP_PATH}" \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost=mariadb \
        --allow-root

    # WordPress'i yükle (site başlığı, admin kullanıcısı)
    # Subject kuralı: admin kullanıcı adı "admin" veya "administrator" içeremez
    wp core install \
        --path="${WP_PATH}" \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    # İkinci (normal) kullanıcı oluştur - subject bunu zorunlu kılar
    wp user create \
        --path="${WP_PATH}" \
        "${WP_USER}" "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author \
        --allow-root

    echo "[WordPress] Kurulum tamamlandı."
fi

# ──────────────────────────────────────────────
# 3. ADIM: PHP-FPM'i ön plana al ve başlat
# ──────────────────────────────────────────────
# "-F" flagı: FPM'i foreground'da çalıştırır (daemon'a dönüşmez)
# Subject: tail -f, sleep infinity gibi hacky yöntemler yasak
exec php-fpm8.2 -F
