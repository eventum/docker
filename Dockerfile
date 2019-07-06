#
# Dockerfile for Eventum
# https://github.com/eventum/eventum
#

FROM phpearth/php:7.1-nginx AS base

FROM base AS source
RUN apk add --no-cache curl

# download and unpack code
WORKDIR /source
ARG VERSION=3.7.1
RUN curl -fLSs https://github.com/eventum/eventum/releases/download/v$VERSION/eventum-$VERSION.tar.xz -o eventum.tar.xz

ARG CHECKSUM=060b2fa8b09cebaf442c2088137998fdfce1082487d83115cafa49bf12834689
RUN sha256sum eventum.tar.xz
RUN echo "$CHECKSUM *eventum.tar.xz" | sha256sum -c -

WORKDIR /app
RUN tar --strip-components=1 -xf /source/eventum.tar.xz
RUN set -x \
	&& chmod -R og-rwX config var \
	&& chown -R www-data: config var \
	&& du -sh

COPY php.ini /php.ini
RUN chmod 644 /php.ini

# build runtime image
FROM base
RUN apk add --no-cache php7.1-gd php7.1-intl php7.1-pdo_mysql
# update to use app root; required to change config as expose only subdir
RUN sed -i -e '/root/ s;/var/www/html;/app/htdocs;' /etc/nginx/conf.d/default.conf

WORKDIR /app
COPY --from=source /php.ini /etc/php/7.1/php.ini
COPY --from=source /app ./
