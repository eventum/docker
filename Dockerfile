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
ARG VERSION=3.7.2
RUN curl -fLSs https://github.com/eventum/eventum/releases/download/v$VERSION/eventum-$VERSION.tar.xz -o eventum.tar.xz

ARG CHECKSUM=adabf6d9f493c44e77a501755857e223ff8a5eec735ef2312e7e81fed48c4758
RUN sha256sum eventum.tar.xz
RUN echo "$CHECKSUM *eventum.tar.xz" | sha256sum -c -

WORKDIR /app
RUN tar --strip-components=1 -xf /source/eventum.tar.xz

WORKDIR /stage
COPY php.ini ./$PHP_INI_DIR/php.ini
COPY bin/entrypoint.sh ./eventum
RUN chmod -R a+rX .

# build runtime image
FROM base
RUN apk add --no-cache php$PHP_VERSION-gd php$PHP_VERSION-intl php$PHP_VERSION-pdo_mysql
ENTRYPOINT [ "/eventum" ]
# update to use app root; required to change config as expose only subdir
RUN sed -i -e '/root/ s;/var/www/html;/app/htdocs;' /etc/nginx/conf.d/default.conf

WORKDIR /app
COPY --from=source /app ./
COPY --from=source /stage /
RUN set -x \
	&& chmod -R og-rwX config var \
	&& chown -R www-data: config var \
	&& du -sh
