# Work derived from official PHP Docker Library:
# Copyright (c) 2014-2015 Docker, Inc.

FROM php:5.6-fpm-jessie

LABEL "com.themeisle.dev"="ThemeIsle"
LABEL "maintainer"="bogdan.preda@themeisle.com"
LABEL "author"="Bogdan Preda"
LABEL "version"="1.0"
LABEL "description"="A docker container w. php 5.6.*, mysql, wp-cli, phpunit, composer and git."

ENV DEBIAN_FRONTEND noninteractive

RUN groupadd -r mysql && useradd -r -g mysql mysql --create-home

# gpg: key 5072E1F5: public key "MySQL Release Engineering <mysql-build@oss.oracle.com>" imported
RUN set -ex; \
	key='A4A9406876FCBD3C456770C88C718D3B5072E1F5'; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	gpg --export "$key" > /etc/apt/trusted.gpg.d/mysql.gpg; \
	rm -r "$GNUPGHOME"; \
	apt-key list > /dev/null

ENV MYSQL_MAJOR 5.7
ENV MYSQL_VERSION 5.7.20-1debian8

RUN echo "deb http://repo.mysql.com/apt/debian/ jessie mysql-${MYSQL_MAJOR}" > /etc/apt/sources.list.d/mysql.list

RUN { \
        echo mysql-community-server mysql-community-server/data-dir select ''; \
        echo mysql-community-server mysql-community-server/root-pass password ''; \
        echo mysql-community-server mysql-community-server/re-root-pass password ''; \
        echo mysql-community-server mysql-community-server/remove-test-db select false; \
    } | debconf-set-selections \
	&& apt-get update && apt-get install -y mysql-server="${MYSQL_VERSION}" && rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql /var/run/mysqld \
	&& chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
	&& chmod 777 /var/run/mysqld
#	&& find /etc/mysql/ -name '*.cnf' -print0 \
#        | xargs -0 grep -lZE '^(bind-address|log)' \
#        | xargs -rt -0 sed -Ei 's/^(bind-address|log)/#&/' \
#    && echo '[mysqld]\nskip-host-cache\nskip-name-resolve' > /etc/mysql/conf.d/docker.cnf

VOLUME /var/lib/mysql

RUN curl -SL --insecure "https://phar.phpunit.de/phpunit.phar" -o phpunit.phar \
    && chmod +x phpunit.phar \
    && mv phpunit.phar /usr/bin/phpunit

RUN apt-get update \
    && apt-get install -y subversion git wget ssh --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

RUN ln -s /var/run/mysqld/mysqld.sock /tmp/mysql.sock

RUN curl --insecure -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

RUN service mysql stop

RUN service mysql start \
    && mysql --user="root" --execute="CREATE DATABASE test;"