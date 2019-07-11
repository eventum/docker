#!/bin/sh
set -eu


bootstrap() {
	test -e config/setup.php && return 0

	cp -a /config/* config
}

upgrade() {
	test -s config/setup.php || return 0

	bin/upgrade.php
}

bootstrap
upgrade || :

exec /sbin/runit-wrapper "$@"
