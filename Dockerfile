#
# Dockerfile for Eventum
# https://github.com/eventum/eventum
#

FROM php:5.6-fpm

ARG EVENTUM_VERSION=3.3.3
ARG EVENTUM_MD5=7fde18feb868ad965aa186418eccd1c1

WORKDIR /usr/src/eventum

# step1: install eventum code
RUN set -xe \
	&& curl -fLSs https://github.com/eventum/eventum/releases/download/v$EVENTUM_VERSION/eventum-$EVENTUM_VERSION.tar.gz -o eventum.tgz \
	&& echo "$EVENTUM_MD5 *eventum.tgz" | md5sum -c - \
	&& tar --strip-components=1 -xzf eventum.tgz \
	&& rm -f eventum.tgz \
	&& chmod -R og-rwX config var \
	&& chown -R www-data: config var \
	&& du -sh

# step2: install dependencies
RUN set -xe \
	&& ln -s /usr/local/bin/php /usr/bin  \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends libpng-dev libmcrypt-dev \
	&& docker-php-ext-install pdo pdo_mysql gd mcrypt \
	&& apt-get remove -y zlib1g-dev libpng12-dev zlib1g-dev libmcrypt-dev \
	&& apt-get clean \
	&& rm -rfv /var/lib/apt/lists/* /tmp/* /var/tmp/* \
	&& php -m

USER www-data
