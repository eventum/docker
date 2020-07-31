#!/bin/sh
set -eu

: ${APP_USER:=www-data}
: ${APP_GROUP:=www-data}

sh_install() {
	install -o $APP_USER -g $APP_GROUP "$@"
}

# https://github.com/karelzak/util-linux/issues/325
# Run command as app user
app_user() {
	local uid=$(id -u $APP_USER)
	local gid=$(id -g $APP_GROUP)

	if [ "$(id -u)" = "0" ]; then
		setpriv --euid "$uid" --ruid "$uid" --clear-groups --egid "$gid" --rgid "$gid" -- "$@"
	else
		"$@"
	fi
}

copy_config() {
	local tmp path file

	tmp=$(mktemp)

	# make dirs
	find /config -type d > $tmp
	while read path; do
		path=$(readlink -f "./${path}")
		test -d "$path" && continue
		sh_install -v -d "$path"
	done < $tmp

	# copy new files
	find /config -type f > $tmp
	while read path; do
		file=$(readlink -f "./${path}")
		test -f "$file" && continue
		sh_install -v -p -m 644 "$path" "$file"
	done < $tmp

	rm -f $tmp
}

fix_permissions() {
	sh_install -d var
	sh_install -d var/cache
	sh_install -d var/lock
	sh_install -d var/log
	sh_install -d var/session
	sh_install -d var/storage
}

bootstrap() {
	copy_config
	fix_permissions
}

upgrade() {
	# skip upgrade on new install
	test -s config/setup.php || return 0

	app_user bin/upgrade.php
}

bootstrap
upgrade || :

exec /sbin/runit-wrapper "$@"
