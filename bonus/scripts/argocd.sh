#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
ARGOCD_URL="${ARGOCD_URL:-https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml}"
INSTALL_TIMEOUT="220s"
RESTART_TIMEOUT="120s"

usage() {
	error "Usage: ${0##*/} {install|password}"
	exit 1
}

# ---------- install ----------
wait_for_server() {
	local timeout="$1"

	kubectl rollout status deployment/argocd-server \
		-n "$ARGOCD_NAMESPACE" --timeout="$timeout"
}

cmd_install() {
	info "Deploying Argo CD in namespace '$ARGOCD_NAMESPACE'..."
	kubectl apply --server-side --force-conflicts \
		-n "$ARGOCD_NAMESPACE" -f "$ARGOCD_URL"

	info "Waiting for Argo CD server to be ready..."
	wait_for_server "$INSTALL_TIMEOUT"

	info "Enabling insecure mode (TLS handled by the ingress)..."
	kubectl patch configmap argocd-cmd-params-cm -n "$ARGOCD_NAMESPACE" \
		--type merge -p '{"data":{"server.insecure":"true"}}'
	kubectl rollout restart deployment argocd-server -n "$ARGOCD_NAMESPACE"

	info "Waiting for Argo CD server to restart..."
	wait_for_server "$RESTART_TIMEOUT"

	success "Argo CD deployed successfully."
}

# ---------- password ----------
cmd_password() {
	local password

	password="$(kubectl -n "$ARGOCD_NAMESPACE" get secret argocd-initial-admin-secret \
		-o jsonpath="{.data.password}" | base64 -d)"
	info "Argo CD admin password: $password"
}

# ---------- Main ----------
[ $# -eq 1 ] || usage

case "$1" in
	install)  cmd_install ;;
	password) cmd_password ;;
	*)        usage ;;
esac