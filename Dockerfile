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
	&& du -sh
