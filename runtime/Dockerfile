#
# Eventum Dockerfile for base runtime
# https://github.com/eventum/eventum
#

FROM php:5.6-fpm

# install dependencies
RUN set -xe \
	&& ln -s /usr/local/bin/php /usr/bin  \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends libpng-dev libmcrypt-dev \
	&& docker-php-ext-install pdo pdo_mysql gd mcrypt \
	&& apt-get remove -y zlib1g-dev libpng12-dev zlib1g-dev libmcrypt-dev \
	&& apt-get clean \
	&& rm -rfv /var/lib/apt/lists/* /tmp/* /var/tmp/* \
	&& php -m

WORKDIR /usr/src/eventum
USER www-data
