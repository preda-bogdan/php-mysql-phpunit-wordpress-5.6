# Work derived from official PHP Docker Library:
# Copyright (c) 2014-2015 Docker, Inc.

FROM php:5.6-fpm-jessie

LABEL "com.themeisle.dev"="ThemeIsle"
LABEL "maintainer"="bogdan.preda@themeisle.com"
LABEL "author"="Bogdan Preda"
LABEL "version"="1.0"
LABEL "description"="A docker container w. php 5.6.*, mysql, wp-cli, phpunit, composer and git."

ENV DEBIAN_FRONTEND noninteractive

RUN { \
        echo mysql-community-server mysql-community-server/root-pass password ''; \
        echo mysql-community-server mysql-community-server/re-root-pass password ''; \
        echo mysql-community-server mysql-community-server/remove-test-db select true; \
    } | debconf-set-selections \
	&& apt-get update && apt-get install -y mysql-server mysql-client php5-mysql && rm -rf /var/lib/apt/lists/*

VOLUME /var/lib/mysql

RUN docker-php-ext-install mysql

RUN curl -SL --insecure "https://phar.phpunit.de/phpunit-5.7.phar" -o phpunit.phar \
    && chmod +x phpunit.phar \
    && mv phpunit.phar /usr/bin/phpunit

RUN apt-get update \
    && apt-get install -y subversion git wget ssh --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

RUN curl --insecure -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

RUN service mysql start \
    && mysql --user="root" --password="" --execute="CREATE DATABASE test;"