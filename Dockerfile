#
# Dockerfile for Eventum
# https://github.com/eventum/eventum
#

# base php version
ARG PHP_VERSION=7.2
FROM phpearth/php:$PHP_VERSION-nginx AS base

ARG PHP_VERSION=7.2
ENV PHP_VERSION $PHP_VERSION

# temporarily until applied upstream: https://github.com/phpearth/docker-php/pull/34
# PHP_INI_DIR to be symmetrical with official php docker image
ENV PHP_INI_DIR /etc/php/$PHP_VERSION

FROM base AS source
RUN apk add --no-cache curl

# download and unpack code
WORKDIR /source
ARG VERSION=3.9.6
RUN curl -fLS https://github.com/eventum/eventum/releases/download/v$VERSION/eventum-$VERSION.tar.xz -o eventum.tar.xz

ARG CHECKSUM=0cd5eadab5f02957b855fa4c54f3e1e13767eaa1c9bd9d9100faa9e8523d23a4
RUN sha256sum eventum.tar.xz && echo "$CHECKSUM *eventum.tar.xz" | sha256sum -c -

WORKDIR /app
RUN tar --strip-components=1 -xf /source/eventum.tar.xz

WORKDIR /stage
COPY php.ini ./$PHP_INI_DIR/php.ini
COPY nginx.conf ./etc/nginx/conf.d/default.conf
COPY php-fpm.conf ./etc/php/$PHP_VERSION/www.conf.extra
COPY bin/entrypoint.sh ./eventum

WORKDIR /app
RUN set -x \
	# not required runtime
	&& rm -r Makefile localization/*.po localization/eventum.pot localization/Makefile localization/LINGUAS.php \
	&& rm -vf var/log/*.log \
	# fixup permissions
	&& install -d config var/session \
	&& chmod -R og-w,o-rwX config var \
	# empty setup file indicates that need to run setup
	&& find config -size 0 -delete \
	# config skeleton for initial setup and upgrades
	&& install -d /stage/config \
	&& mv config/* /stage/config \
	&& chown -R www-data:www-data config var \
	# add vendor as separate docker layer
	&& mv vendor / \
	&& du -sh /app /vendor

# build runtime image
FROM base
WORKDIR /app
ENTRYPOINT [ "/eventum" ]

RUN apk add --no-cache \
	setpriv \
	php$PHP_VERSION-gd \
	php$PHP_VERSION-gettext \
	php$PHP_VERSION-intl \
	php$PHP_VERSION-ldap \
	php$PHP_VERSION-pdo_mysql \
	&& exit 0

COPY --from=source /stage /
RUN cat /etc/php/$PHP_VERSION/www.conf.extra >> /etc/php/$PHP_VERSION/php-fpm.d/www.conf

COPY --from=source /vendor ./vendor/
COPY --from=source /app ./
