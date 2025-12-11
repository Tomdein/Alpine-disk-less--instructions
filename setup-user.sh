#!/bin/sh
set -euo pipefail

# Basically:
# 1. adduser
# 2. setup ssh keys in .ssh/authorized_keys
# 3. add to groups
# 4. setup doas for admin users

PREFIX=@PREFIX@
: ${LIBDIR=$PREFIX/lib}
. "$LIBDIR/libalpine.sh"

while getopts "a" opt; do
	case $opt in
		a) admin=1;;
		'?') usage "1" >&2;;
	esac
done

ask "Setup a user? (enter a lower-case loginname, or 'no')"
case "$resp" in
    no) exit 0;;
    *) username="$resp";;
esac
ask "Full name for user $username" ${lastfullname:-$username}

adduser -g "$fullname" -D "$username" && break

if [ -n "$sshkeys" ] && [ "$sshkeys" != "none" ]; then
	ssh_directory="$ROOT"/home/$username/.ssh
	(
		umask 077
		mkdir -p "$ssh_directory"
		echo "$sshkeys" > "$ssh_directory"/authorized_keys
	)
	chown -R $username:$username "$ssh_directory"
fi

# if [ -n "$groups" ] && [ "$groups" != "none" ]; then
# 	for i in $(echo $groups | tr ',' ' '); do
# 		addgroup "$username" "$i" || exit
# 	done
# fi

if [ -n "$admin" ]; then
	apk add doas
	mkdir -p "$ROOT"/etc/doas.d
	echo "permit persist :wheel" >> "$ROOT"/etc/doas.d/20-wheel.conf
	addgroup "$username" "wheel" || exit
fi
