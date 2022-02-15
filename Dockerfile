# docker build -t misaelgomes/php74-fpm-mage-cron .
# docker run -d -p 3142:3142 misaelgomes/eg_apt_cacher_ng
# docker run -d -p 3142:3142 misaelgomes/eg_apt_cacher_ng
# docker run -d -i -t -p 3142:3142 misaelgomes/eg_apt_cacher_ng debian bash
# acessar localhost:3142 copiar proxy correto e colar abaixo em Acquire
# docker run -d -p 80:80 misaelgomes/tengine-php74

# From PHP 7.4 FPM based on Alpine Linux
FROM php:7.4-fpm

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Sao_Paulo
RUN dpkg-reconfigure tzdata

RUN echo 'Acquire::http { Proxy "http://172.17.0.2:3142"; };' >> /etc/apt/apt.conf.d/01proxy
VOLUME ["/var/cache/apt-cacher-ng"]

#deps
RUN apt-get update --fix-missing -y
RUN apt-get install -y gcc make autoconf pkg-config build-essential software-properties-common  
RUN apt-get install -y tar zip unzip zlib1g-dev zlib1g libzip-dev libbz2-dev
RUN apt-get install -y optipng gifsicle jpegoptim libfreetype6-dev libjpeg62-turbo-dev libpng-dev
RUN apt-get install -y libgd3 libgd-dev libgd-tools webp libwebp-dev imagemagick
RUN apt-get install -y ca-certificates openssl curl tzdata libxslt-dev
RUN apt-get install -y libc-dev libssl-dev git libonig-dev libmcrypt-dev
RUN apt-get install -y nano libxml2-dev libjemalloc-dev libjemalloc2 libcurl4-openssl-dev
RUN apt-get install -y libmagickwand-dev libmemcached-dev libmemcached-tools
RUN apt-get install -y sendmail mailutils cron


#megapack
RUN apt-get install -y libxss1 libxss-dev
RUN apt-get install -y libxcursor1 libxcursor-dev
RUN apt-get install -y libgtk-3-0 libgtk-3-dev libgtk-3-bin libgtk-3-common
RUN apt-get install -y npm
RUN apt-get install -y gconf-service libasound2 libatk1.0-0 libatk-bridge2.0-0 libc6 libcairo2  libnss3 lsb-release 
RUN apt-get install -y libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4
RUN apt-get install -y libgdk-pixbuf2.0-0 libglib2.0-0 libnspr4 libpango-1.0-0
RUN apt-get install -y libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1
RUN apt-get install -y libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1
RUN apt-get install -y libxtst6 fonts-liberation
RUN apt-get install -y xdg-utils wget
RUN npm install -g magepack --unsafe-perm=true
RUN apt-get install -y gnupg && npm install -g grunt-cli

RUN cd /usr/local/lib/node_modules/magepack 
RUN npm install puppeteer --save --unsafe-perm --allow-root


# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
ENV COMPOSER_ALLOW_SUPERUSER=1

# Hack to change uid of 'www-data' to 1000
#RUN usermod -u 1000 www-data

RUN pecl channel-update pecl.php.net
RUN echo yes | pecl install imagick igbinary
RUN echo yes | pecl install lzf
RUN echo yes | pecl install redis
#RUN echo yes | pecl install xdebug
RUN echo yes | pecl install memcached

RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp
RUN docker-php-ext-install gd soap pdo_mysql opcache mbstring \
        mysqli gettext calendar calendar bz2 exif gettext \
        sockets sysvmsg sysvsem sysvshm xsl zip xmlrpc intl
RUN docker-php-ext-enable igbinary redis lzf imagick memcached intl
#RUN docker-php-ext-enable xdebug

RUN echo "America/Sao_Paulo" > /etc/timezone
RUN date

RUN echo "sendmail_path=/usr/sbin/sendmail -t -i" >> /usr/local/etc/php/conf.d/sendmail.ini

RUN chown www-data:www-data -R /var/www/html
RUN apt-get remove -y gcc flex make bison build-essential pkg-config \
        g++ libtool automake autoconf
RUN apt-get remove --purge --auto-remove -y \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*
        
RUN rm -fr /tmp/*

COPY ./mage-cron.1 /etc/cron.d/mage-cron
RUN crontab -u www-data /etc/cron.d/mage-cron
RUN chmod u+s /usr/sbin/cron

#RUN echo "* * * * * www-data /usr/local/bin/php /var/www/html/bin/magento cron:run 2>&1 | grep -v "Ran jobs by schedule" >> /var/www/html/var/log/magento.cron.log" >> /etc/crontab

RUN usermod -s /bin/bash www-data

USER www-data

EXPOSE 9000

CMD bash -c "cron && php-fpm"
