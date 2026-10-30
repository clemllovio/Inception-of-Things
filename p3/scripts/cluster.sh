#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/../config.env"

: "${HTTP_PORT:?HTTP_PORT is not set}"

usage() {
	error "Usage: ${0##*/} {create|delete|status} CLUSTER_NAME"
	exit 1
}

cluster_exists() {
	k3d cluster get "$1" >/dev/null 2>&1
}

# ---------- create ----------
cmd_create() {
	local name="$1"

	if cluster_exists "$name"; then
		info "Cluster '$name' already exists."
	else
		info "Creating cluster '$name'..."
		k3d cluster create "$name" -p "${HTTP_PORT}:80@loadbalancer"
		success "Cluster '$name' created successfully."
	fi
	cmd_status "$name"
}

# ---------- delete ----------
cmd_delete() {
	local name="$1"

	info "Deleting K3d cluster '$name'..."
	if cluster_exists "$name"; then
		k3d cluster delete "$name"
		success "Cluster '$name' deleted successfully."
	else
		info "No cluster '$name' found."
	fi
}

# ---------- status ----------
cmd_status() {
	local name="$1"

	success "=== Kubernetes Node Status ==="
	kubectl get nodes -o wide
	success "=== K3d Cluster List ==="
	k3d cluster list
	success "=== Associated Docker Containers ==="
	docker ps --filter "name=k3d-${name}"
}

# ---------- Main ----------
[ $# -eq 2 ] || usage

action="$1"
name="$2"

case "$action" in
	create) cmd_create "$name" ;;
	delete) cmd_delete "$name" ;;
	status) cmd_status "$name" ;;
	*)      usage ;;
esac