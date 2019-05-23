#
# Dockerfile for Eventum
# https://github.com/eventum/eventum
#

FROM php:7.1-fpm-alpine AS base

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

# build runtime image
FROM base
WORKDIR /app
COPY --from=source /app ./
USER www-data
