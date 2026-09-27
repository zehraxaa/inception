#!/bin/bash

set -e

SSL_DIR="/etc/nginx/ssl"
SSL_CRT="${SSL_DIR}/aaydogdu.42.fr.crt"
SSL_KEY="${SSL_DIR}/aaydogdu.42.fr.key"

if [ ! -f "${SSL_CRT}" ]; then
    mkdir -p "${SSL_DIR}"
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout "${SSL_KEY}" \
        -out "${SSL_CRT}" \
        -subj "/CN=aaydogdu.42.fr"
    echo "SSL sertifikası oluşturuldu."
fi

nginx -t

exec nginx -g "daemon off;"