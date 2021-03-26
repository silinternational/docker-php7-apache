FROM php:7.4-apache
LABEL maintainer="matt_henderson@sil.org"

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        unzip \
        zip \
        cron \
# Needed to get various scripts
        curl \
# Needed for whenavail
        netcat \
# Needed to build php extensions
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libonig-dev \
        libxml2-dev \
        libcurl4-openssl-dev

COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
RUN curl https://bitbucket.org/silintl/docker-whenavail/raw/1.0.2/whenavail -o /usr/local/bin/whenavail
RUN chmod a+x /usr/local/bin/whenavail
RUN curl https://raw.githubusercontent.com/silinternational/runny/0.2/runny -o /usr/local/bin/runny
RUN chmod a+x /usr/local/bin/runny

# Install and enable, see the README on the docker hub for the image
RUN docker-php-ext-configure gd --with-freetype=/usr/include --with-jpeg=/usr/include && \
    docker-php-ext-install -j$(nproc) gd && \
    docker-php-ext-install pdo pdo_mysql mbstring xml curl && \
    docker-php-ext-enable gd pdo pdo_mysql mbstring xml curl

# .htaccess file needs Rewrite and Headers modules
RUN a2enmod rewrite
RUN a2enmod headers

# ErrorLog inside a VirtualHost block is ineffective for unknown reasons
RUN sed -i -E 's@ErrorLog .*@ErrorLog /proc/self/fd/2@i' /etc/apache2/apache2.conf

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

EXPOSE 80

# Make sure the default site is disabled
RUN a2dissite 000-default

CMD ["/data/run.sh"]
