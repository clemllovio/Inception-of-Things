#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
	error "Usage: ${0##*/} create NAMESPACE... | ${0##*/} status"
	exit 1
}

namespace_exists() {
	kubectl get namespace "$1" >/dev/null 2>&1
}

# ---------- create ----------
create_namespace() {
	local ns="$1"

	if namespace_exists "$ns"; then
		info "Namespace '$ns' already exists."
	else
		info "Creating namespace '$ns'..."
		run_quiet kubectl create namespace "$ns"
	fi
}

cmd_create() {
	step "Creating namespaces"
	
	for ns in "$@"; do
		create_namespace "$ns"
	done
	success "Namespaces created successfully."
}

# ---------- status ----------
cmd_status() {
	success "=== Namespaces list ==="
	kubectl get namespaces
}

# ---------- Main ----------
[ $# -ge 1 ] || usage

action="$1"
shift

case "$action" in
	create) cmd_create "$@" ;;
	status) cmd_status ;;
	*)      usage ;;
esac