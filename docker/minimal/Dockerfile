# PHP 8.4+ is not supported by the bundled Twig 2.15.4 (closure names changed)
FROM docker.io/php:8.3-apache-trixie

ENV MYAAC_CONFIG_DIR=/config

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

RUN apt-get update -yq \
  && apt-get install -yq --no-install-recommends libfreetype6-dev libjpeg62-turbo-dev libpng-dev libzip-dev \
  && docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install -j"$(nproc)" bcmath calendar gd pdo_mysql zip \
  && a2enmod rewrite \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

RUN mkdir -p /config && chown -R www-data:www-data /config

COPY --chown=www-data:www-data . .
RUN mv .htaccess.dist .htaccess \
  && echo '*' > install/ip.txt \
  && install -d -o www-data -g www-data system/logs

VOLUME /config /var/www/html/system/cache
