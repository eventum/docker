#
# Dockerfile for Eventum
# https://github.com/eventum/eventum
#

ARG BUILDTYPE=download

FROM alpine:3.12 AS base
ENV PHP_VERSION 7.3

# PHP_INI_DIR to be symmetrical with official php docker image
ENV PHP_INI_DIR /etc/php7

FROM base AS source-download
RUN apk add --no-cache curl

# download and unpack code
WORKDIR /source
ARG VERSION=3.10.6
RUN curl -fLS https://github.com/eventum/eventum/releases/download/v$VERSION/eventum-$VERSION.tar.xz -o eventum.tar.xz

ARG CHECKSUM=ad97e8fae8203f8388d2ebab22e7f9fa0d307e45ab4527541cd670749769c915
RUN sha256sum eventum.tar.xz && echo "$CHECKSUM *eventum.tar.xz" | sha256sum -c -

FROM base AS source-local
COPY eventum-*.tar.xz /source/eventum.tar.xz

# Copy runit initscript from previous version
FROM eventum/eventum:3.9.12 AS runit-base
FROM base AS runit
WORKDIR /runit
COPY --from=runit-base /sbin/runit-wrapper ./sbin/runit-wrapper
COPY --from=runit-base /sbin/runsvdir-start ./sbin/runsvdir-start
COPY --from=runit-base /etc/service ./etc/service/

FROM source-$BUILDTYPE AS source

# Use www-data uid/gid, same as in docker php alpine images
RUN addgroup -g 82 www-data
RUN adduser -u 82 -D -S -G www-data www-data

WORKDIR /app
RUN tar --strip-components=1 -xf /source/eventum.tar.xz

WORKDIR /stage
COPY --from=runit /runit ./
COPY php.ini ./$PHP_INI_DIR/php.ini
COPY nginx.conf ./etc/nginx/conf.d/default.conf
COPY php-fpm.conf ./$PHP_INI_DIR/www.conf.extra
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
VOLUME [ "/run/nginx", "/run/php" ]

RUN apk add --no-cache \
		nginx \
		php7-cli \
		php7-ctype \
		php7-dom \
		php7-fileinfo \
		php7-fpm \
		php7-gd \
		php7-gettext \
		php7-iconv \
		php7-intl \
		php7-json \
		php7-ldap \
		php7-mbstring \
		php7-pdo_mysql \
		php7-session \
		php7-tokenizer \
		php7-xml \
		runit \
		setpriv \
	&& exit 0

RUN set -x \
	&& adduser -u 82 -D -S -G www-data www-data \
	&& ln -s php-fpm7 /usr/sbin/php-fpm \
	&& ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log \
	&& exit 0

LABEL org.opencontainers.image.source "https://github.com/eventum/eventum"

COPY --from=source /vendor ./vendor/
COPY --from=source /stage /
RUN cat $PHP_INI_DIR/www.conf.extra >> $PHP_INI_DIR/php-fpm.d/www.conf
COPY --from=source /app ./
