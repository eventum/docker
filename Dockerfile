#
# Dockerfile for Eventum
# https://github.com/eventum/eventum
#

ARG BUILDTYPE=download

# base php version
ARG PHP_VERSION=7.2
FROM phpearth/php:$PHP_VERSION-nginx AS base

ARG PHP_VERSION=7.2
ENV PHP_VERSION $PHP_VERSION

# temporarily until applied upstream: https://github.com/phpearth/docker-php/pull/34
# PHP_INI_DIR to be symmetrical with official php docker image
ENV PHP_INI_DIR /etc/php/$PHP_VERSION

FROM base AS source-download
RUN apk add --no-cache curl

# download and unpack code
WORKDIR /source
ARG VERSION=3.10.0
RUN curl -fLS https://github.com/eventum/eventum/releases/download/v$VERSION/eventum-$VERSION.tar.xz -o eventum.tar.xz

ARG CHECKSUM=7971d890c8a1a0511c7890c222407563eed468aebba2fddf9d76361cd949df73
RUN sha256sum eventum.tar.xz && echo "$CHECKSUM *eventum.tar.xz" | sha256sum -c -

FROM base AS source-local
COPY eventum-*.tar.xz /source/eventum.tar.xz

FROM source-$BUILDTYPE AS source

WORKDIR /app
RUN tar --strip-components=1 -xf /source/eventum.tar.xz

WORKDIR /stage
COPY php.ini ./$PHP_INI_DIR/php.ini
COPY nginx.conf ./etc/nginx/conf.d/default.conf
COPY php-fpm.conf ./etc/php/$PHP_VERSION/www.conf.extra
COPY bin/entrypoint.sh ./eventum

ARG DATE=2021-03-10
ARG TIME=19:33:10
WORKDIR /app
RUN set -x \
	# not required runtime
	&& rm -r Makefile localization/*.po localization/eventum.pot localization/Makefile localization/LINGUAS.php \
	&& rm -vf var/log/*.log \
	# fixup permissions
	&& install -d config var/session \
	&& chmod -R og-w,o-rwX config var \
	# empty setup file indicates that need to run setup
	&& find config -type f -size 0 -delete \
	# config skeleton for initial setup and upgrades
	&& install -d /stage/config \
	&& mv config/* /stage/config \
	&& chown -R www-data:www-data config var \
	# make build reproducible by using fixed timestamp
	# we timestamp files in eventum tarball, but not dirs
	&& find -type d | xargs touch -d "$DATE" -t "$TIME" \
	# common timestamp for all files in vendor until composer supports that itself
	# https://github.com/composer/composer/issues/9768
	&& find vendor -type f | xargs touch -d "$DATE" -t "$TIME" \
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

COPY --from=source /vendor ./vendor/

COPY --from=source /stage /
RUN cat /etc/php/$PHP_VERSION/www.conf.extra >> /etc/php/$PHP_VERSION/php-fpm.d/www.conf
COPY --from=source /app ./
