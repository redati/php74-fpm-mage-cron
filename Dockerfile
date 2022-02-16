# docker build -t misaelgomes/php74-fpm-mage-cron .
# docker run -d -p 3142:3142 misaelgomes/eg_apt_cacher_ng
# docker run -d -p 3142:3142 misaelgomes/eg_apt_cacher_ng
# docker run -d -i -t -p 3142:3142 misaelgomes/eg_apt_cacher_ng debian bash
# acessar localhost:3142 copiar proxy correto e colar abaixo em Acquire
# docker run -d -p 80:80 misaelgomes/tengine-php74

# From PHP 7.4 FPM based on Alpine Linux
FROM misaelgomes/php74-fpm

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Sao_Paulo
RUN dpkg-reconfigure tzdata

RUN echo 'Acquire::http { Proxy "http://172.17.0.2:3142"; };' >> /etc/apt/apt.conf.d/01proxy
VOLUME ["/var/cache/apt-cacher-ng"]

#deps
RUN apt-get update --fix-missing -y

RUN apt-get install -y  cron


COPY ./mage-cron.1 /etc/cron.d/mage-cron
RUN crontab -u www-data /etc/cron.d/mage-cron
RUN chmod u+s /usr/sbin/cron

#RUN echo "* * * * * www-data /usr/local/bin/php /var/www/html/bin/magento cron:run 2>&1 | grep -v "Ran jobs by schedule" >> /var/www/html/var/log/magento.cron.log" >> /etc/crontab

RUN usermod -s /bin/bash www-data

USER www-data

EXPOSE 9000

CMD bash -c "cron && php-fpm"
