FROM ubuntu:16.04


# Define default answers for debconf and set
# debian frontend to noninteractive mode.
COPY scripts/*.sh /scripts/
RUN chmod +x /scripts/*
RUN /scripts/defaults.sh
RUN export DEBIAN_FRONTEND=noninteractive

ADD https://deb.nodesource.com/setup_6.x /scripts/nodejs.sh
RUN chmod +x /scripts/nodejs.sh && sync && /scripts/nodejs.sh
RUN rm -f /scripts/nodejs.sh

# Install packages
RUN apt-get clean && apt-get -y update && apt-get install -y locales software-properties-common \
  && locale-gen en_US.UTF-8
RUN LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php
RUN apt -y update && apt install -y \
    memcached \
    nginx \
    php-memcached \
    php7.1 \
    php7.1-gd \
    php7.1-curl \
    php7.1-fpm \
    php7.1-mcrypt \
    php7.1-mbstring \
    php7.1-mysql \
    php7.1-tidy \
    php7.1-zip \
    php7.1-dom \
    phpmyadmin \
    mysql-client-5.7 \
    composer \
    nodejs \
    supervisor \
    && echo 'Packages installed'

# Add configuration files
COPY conf/php/* /etc/php/7.1/fpm/conf.d
COPY conf/nginx/conf.d/* /etc/nginx/conf.d/
COPY conf/nginx/sites/* /etc/nginx/sites-enabled/
COPY conf/nginx/sites/* /etc/nginx/sites-available/
COPY conf/phpmyadmin/* /etc/phpmyadmin/

# Disable daemon mode on php-fpm
RUN sed -i 's/;daemonize = yes/daemonize = no/g' /etc/php/7.1/fpm/php-fpm.conf

# Create run directories for mysql and php-fpm
RUN mkdir /var/run/php

# Add supervisord configuration files
COPY supervisord/* /etc/supervisor/conf.d/

# Expose HTTP port
EXPOSE 80

CMD ["/scripts/run.sh"]

