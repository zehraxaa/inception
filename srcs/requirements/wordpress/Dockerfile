FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-curl \
    php8.2-gd \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-zip \
    curl \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

COPY tools/wordpress_start.sh /usr/local/bin/wordpress_start.sh
RUN chmod +x /usr/local/bin/wordpress_start.sh

WORKDIR /var/www/wordpress          
#diyorum ki artık wordpress dosyaları burda tutulacak

EXPOSE 9000
#wordpress nginx ile iletişim için sadece 9000 portunu kullanır

ENTRYPOINT ["/usr/local/bin/wordpress_start.sh"]