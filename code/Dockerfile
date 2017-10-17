#
# Eventum Dockerfile for versioned code
# https://github.com/eventum/eventum
#

# base image irrelevant, use image which is already pulled
FROM php:5.6-fpm AS build

ARG EVENTUM_VERSION=3.3.2
ARG EVENTUM_MD5=e6db7269d27280dcde36c4321f6c0cd0

WORKDIR /build

RUN curl -fLSs https://github.com/eventum/eventum/releases/download/v$EVENTUM_VERSION/eventum-$EVENTUM_VERSION.tar.gz -o /eventum.tgz
RUN cd / && echo "$EVENTUM_MD5 *eventum.tgz" | md5sum -c -
RUN tar --strip-components=1 -xzf /eventum.tgz
RUN chmod -R og-rwX config var
RUN chown -R www-data: config var
RUN du -sh

# create image containing only code
FROM glen/scratch
COPY --from=build /build /usr/src/eventum
