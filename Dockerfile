#
# Dockerfile for Eventum
# https://github.com/eventum/eventum
#

# base php version
ARG PHP_VERSION=7.1
FROM phpearth/php:$PHP_VERSION-nginx AS base

ARG PHP_VERSION=7.1
ENV PHP_VERSION $PHP_VERSION

# temporarily until applied upstream: https://github.com/phpearth/docker-php/pull/34
# PHP_INI_DIR to be symmetrical with official php docker image
ENV PHP_INI_DIR /etc/php/$PHP_VERSION

FROM base AS source
RUN apk add --no-cache curl

# download and unpack code
WORKDIR /source
ARG VERSION=3.7.4
RUN curl -fLS https://github.com/eventum/eventum/releases/download/v$VERSION/eventum-$VERSION.tar.xz -o eventum.tar.xz

ARG CHECKSUM=76f85ef2692e253c1a0823fd57c06ea204c46632e542cb1e822438369543d29a
RUN sha256sum eventum.tar.xz
RUN echo "$CHECKSUM *eventum.tar.xz" | sha256sum -c -

WORKDIR /app
RUN tar --strip-components=1 -xf /source/eventum.tar.xz

WORKDIR /stage
COPY php.ini ./$PHP_INI_DIR/php.ini
COPY bin/entrypoint.sh ./eventum

# config skeleton for initial setup and upgrades
RUN mv /app/config ./config

RUN set -x \
	&& install -d /app/config \
	&& chmod -R og-w /app \
	&& chmod -R og-w,o-rwX ./config /app/var/* \
	&& chown -R www-data:www-data ./config /app/var/* \
	&& rm -vf /app/var/log/*.log \
	&& du -sh /app

# build runtime image
FROM base
WORKDIR /app
ENTRYPOINT [ "/eventum" ]
# update to use app root; required to change config as expose only subdir
RUN sed -i -e '/root/ s;/var/www/html;/app/htdocs;' /etc/nginx/conf.d/default.conf

RUN apk add --no-cache \
	php$PHP_VERSION-gd \
	php$PHP_VERSION-intl \
	php$PHP_VERSION-ldap \
	php$PHP_VERSION-pdo_mysql \
	&& exit 0

COPY --from=source /app ./
COPY --from=source /stage /
