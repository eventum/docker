#
# Dockerfile for Eventum
# https://github.com/eventum/eventum
#

FROM php:5.6-fpm

ENV EVENTUM_VERSION 3.1.3

WORKDIR /src/eventum

RUN \
	curl -LSs https://github.com/eventum/eventum/releases/download/v$EVENTUM_VERSION/eventum-$EVENTUM_VERSION.tar.gz | \
	tar --strip-components=1 -xzv
