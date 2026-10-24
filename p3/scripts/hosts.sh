#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.env"

: "${HOSTS_FILE:?HOSTS_FILE is not set}"
: "${HOSTS_IP:?HOSTS_IP is not set}"

usage() {
	echo "Usage: ${0##*/} {add|remove} HOST..." >&2
	exit 1
}

host_exists() {
	grep -qw "$1" "$HOSTS_FILE"
}

add_host() {
	host="$1"

	if host_exists "$host"; then
		echo "$host already in $HOSTS_FILE."
	else
		echo "Adding $host to $HOSTS_FILE..."
		echo "$HOSTS_IP $host" | sudo tee -a "$HOSTS_FILE" >/dev/null
	fi
}

remove_host() {
	host="$1"

	if host_exists "$host"; then
		echo "Removing $host from $HOSTS_FILE..."
		sudo sed -i "/$host/d" "$HOSTS_FILE"
	else
		echo "$host not in $HOSTS_FILE."
	fi
}

# ---------- Main ----------
[ $# -ge 2 ] || usage   # Check the number of arg  

action="$1"
shift       # Remove action : "$@" contains only hosts

case "$action" in
	add)    for host in "$@"; do add_host "$host"; done ;;
	remove) for host in "$@"; do remove_host "$host"; done ;;
	*)      usage ;;
esac