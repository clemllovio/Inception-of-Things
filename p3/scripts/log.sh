#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
	echo "Usage: ${0##*/} {info|success|warn|error} MESSAGE..." >&2
	exit 1
}

# ---------- Main ----------
[ $# -ge 2 ] || usage

level="$1"
shift

case "$level" in
	info)    info "$@" ;;
	success) success "$@" ;;
	warn)    warn "$@" ;;
	error)   error "$@" ;;
	*)       usage ;;
esac