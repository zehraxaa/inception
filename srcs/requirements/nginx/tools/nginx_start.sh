#!/bin/bash

set -e

nginx -t

if [ ! -f /etc/ssl/certs/nginx.crt ]; then
    RUN openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/aaydogdu.42.fr.key \
    -out /etc/nginx/ssl/aaydogdu.42.fr.crt \
    -subj "/CN=aaydogdu.42.fr

exec nginx -g "deamon off;"