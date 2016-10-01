#
# Dockerfile for Eventum
# https://github.com/eventum/eventum
#

FROM php:5.6-fpm

ENV EVENTUM_VERSION 3.1.3
ENV EVENTUM_MD5 23b9d81da34d7556e06f09fef81bdc7e

WORKDIR /src/eventum

RUN set -xe \
	&& curl -fLSs https://github.com/eventum/eventum/releases/download/v$EVENTUM_VERSION/eventum-$EVENTUM_VERSION.tar.gz -o eventum.tgz \
	&& echo "$EVENTUM_MD5 *eventum.tgz" | md5sum -c - \
	&& tar --strip-components=1 -xzf eventum.tgz \
	&& rm -f eventum.tgz \
	&& apt-get update \
	&& apt-get install -y libpng-dev libmcrypt-dev \
	&& docker-php-ext-install pdo pdo_mysql gd mcrypt \
	&& apt-get remove -y zlib1g-dev libpng12-dev zlib1g-dev libmcrypt-dev \
	&& apt-get clean \
	&& rm -rfv /var/lib/apt/lists/* /tmp/* /var/tmp/* \
	&& chmod -R og-rwX config var \
	&& chown -R www-data: config var \
	&& du -sh

USER www-data
