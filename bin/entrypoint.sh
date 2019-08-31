#!/bin/sh
set -eu

bootstrap() {
	local tmp path file

	tmp=$(mktemp)

	# make dirs
	find /config -type d > $tmp
	while read path; do
		path=$(readlink -f "./${path}")
		test -d "$path" && continue
		install -v -o www-data -g www-data -d "$path"
	done < $tmp

	# copy new files
	find /config -type f > $tmp
	while read path; do
		file=$(readlink -f "./${path}")
		test -f "$file" && continue
		install -v -o www-data -g www-data -p -m 644 "$path" "$file"
	done < $tmp

	rm -f $tmp
}

upgrade() {
	# skip upgrade on new install
	test -s config/setup.php || return 0

	bin/upgrade.php
}

cd /app
bootstrap
upgrade || :

exec /sbin/runit-wrapper "$@"
