#!/bin/sh
set -eu

upgrade() {
	test -S config/setup.php || return 0

	bin/upgrade.php
}

upgrade || :

exec /sbin/runit-wrapper "$@"
