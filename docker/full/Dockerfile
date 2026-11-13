# PHP 8.4+ is not supported by the bundled Twig 2.15.4 (closure names changed)
FROM docker.io/php:8.3-apache-trixie

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

ARG APCU_VERSION=5.1.28

# Install system dependencies & PHP extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    nano \
  && docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install -j"$(nproc)" bcmath calendar gd pdo_mysql zip \
  && pecl install apcu-${APCU_VERSION} && docker-php-ext-enable apcu \
  && a2enmod rewrite \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY docker/full/php.ini /usr/local/etc/php/conf.d/99-myaac.ini

# Server data read by MyAAC, taken from Crystal Server at a fixed commit
# (keep in sync with Dockerfile-db)
ARG CRYSTALSERVER_REF=7c6c330899cd0a4d6547d7416a0d3f5bdbd29a3e
ARG CRYSTALSERVER_RAW=https://raw.githubusercontent.com/zimbadev/crystalserver/${CRYSTALSERVER_REF}
ADD ${CRYSTALSERVER_RAW}/config.lua.dist /srv/server/config.lua
ADD ${CRYSTALSERVER_RAW}/data/stages.lua /srv/server/data/stages.lua
ADD ${CRYSTALSERVER_RAW}/data/XML/vocations.xml /srv/server/data/XML/vocations.xml
ADD ${CRYSTALSERVER_RAW}/data/XML/groups.xml /srv/server/data/XML/groups.xml
ADD ${CRYSTALSERVER_RAW}/data/XML/events.xml /srv/server/data/XML/events.xml
ADD ${CRYSTALSERVER_RAW}/data/items/items.xml /srv/server/data/items/items.xml

# Point config.lua to the database container (last assignment wins)
COPY docker/full/config-overrides.lua /tmp/config-overrides.lua
RUN cat /tmp/config-overrides.lua >> /srv/server/config.lua \
  && rm /tmp/config-overrides.lua \
  && chmod -R a+rX /srv/server

# config.local.php is saved here (see MYAAC_CONFIG_DIR)
RUN mkdir -p /config && chown www-data:www-data /config

WORKDIR /var/www/html

COPY --chmod=755 docker/full/entrypoint.sh /usr/local/bin/myaac-entrypoint

ENTRYPOINT ["myaac-entrypoint"]
CMD ["apache2-foreground"]
