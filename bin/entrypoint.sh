#!/bin/sh
set -eu

upgrade() {
	test -s config/setup.php || return 0

	bin/upgrade.php
}

upgrade || :

exec /sbin/runit-wrapper "$@"
