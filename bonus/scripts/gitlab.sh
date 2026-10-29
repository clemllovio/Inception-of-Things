#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${ROOT_DIR}/config.env"

GITLAB_VERSION="${GITLAB_VERSION:?GITLAB_VERSION is not set}"
GITLAB_NAMESPACE="${GITLAB_NAMESPACE:-gitlab}"
HELM_TIMEOUT="${GITLAB_HELM_TIMEOUT:-900s}"
MIGRATIONS_TIMEOUT="${GITLAB_MIGRATIONS_TIMEOUT:-200s}"
WEBSERVICE_TIMEOUT="${GITLAB_WEBSERVICE_TIMEOUT:-200s}"
GITLAB_HOST="${GITLAB_HOST:-gitlab.local}"
GITLAB_PROJECT="${GITLAB_PROJECT:-iot_cllovio}"
APP_DIR="${APP_DIR:-${ROOT_DIR}/app}"
API_BASE="http://127.0.0.1:${HTTP_PORT:?HTTP_PORT is not set}"

usage() {
	error "Usage: ${0##*/} {install|password|status|repo}"
	exit 1
}

# ---------- install ----------
wait_for_gitlab() {
	info "Waiting for migrations..."
	kubectl wait --for=condition=complete job -l app=migrations \
		-n "$GITLAB_NAMESPACE" --timeout="$MIGRATIONS_TIMEOUT"

	info "Waiting for webservice..."
	kubectl rollout status deploy/gitlab-webservice-default \
		-n "$GITLAB_NAMESPACE" --timeout="$WEBSERVICE_TIMEOUT"
}

cmd_install() {
	info "Deploying GitLab ${GITLAB_VERSION} in namespace '$GITLAB_NAMESPACE'..."
	helm repo add gitlab https://charts.gitlab.io/ --force-update
	helm upgrade --install gitlab gitlab/gitlab \
		-n "$GITLAB_NAMESPACE" \
		--version "$GITLAB_VERSION" \
		--skip-crds \
		-f "${ROOT_DIR}/.values/dev-external.values.yaml" \
		-f "${ROOT_DIR}/confs/gitlab-values.yaml" \
		--timeout "$HELM_TIMEOUT"

	wait_for_gitlab
	success "GitLab is ready."
}

# ---------- password ----------
cmd_password() {
	local password

	password="$(kubectl get secret gitlab-gitlab-initial-root-password \
		-n "$GITLAB_NAMESPACE" -o jsonpath='{.data.password}' | base64 -d)"
	info "GitLab root password: $password"
}

# ---------- status ----------
cmd_status() {
	success "=== Pods ==="
	kubectl get pods -n "$GITLAB_NAMESPACE"
	success "=== Ingress ==="
	kubectl get ingress -n "$GITLAB_NAMESPACE"
}

# ---------- repo ----------
GITLAB_TOKEN=""

create_token() {
	kubectl exec -n "$GITLAB_NAMESPACE" deploy/gitlab-toolbox -c toolbox -- \
		gitlab-rails runner "
		user = User.find_by_username('root')
		user.personal_access_tokens.where(name: 'iot-bootstrap').destroy_all
		t = user.personal_access_tokens.create!(name: 'iot-bootstrap', scopes: [:api, :write_repository], expires_at: 30.days.from_now)
		t.set_token('${GITLAB_TOKEN}')
		t.save!
		" >/dev/null
}

api() {
	local path="$1"
	shift

	curl -fsS -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" -H "Host: ${GITLAB_HOST}" \
		"${API_BASE}/api/v4/${path}" "$@"
}

project_exists() {
	api "projects/root%2F${GITLAB_PROJECT}" >/dev/null 2>&1
}

repo_url() {
	echo "http://root:${GITLAB_TOKEN}@127.0.0.1:${HTTP_PORT}/root/${GITLAB_PROJECT}.git"
}

push_code() {
	TMP_DIR="$(mktemp -d)"
	trap 'rm -rf "$TMP_DIR"' EXIT

	cp -r "${APP_DIR}/." "$TMP_DIR"
	
	api "projects/root%2F${GITLAB_PROJECT}/protected_branches/main" -X DELETE >/dev/null 2>&1 || true

	git -C "$TMP_DIR" init -q -b main
	git -C "$TMP_DIR" add -A
	git -C "$TMP_DIR" -c user.name=iot -c user.email=iot@local commit -qm "Import app"
	git -C "$TMP_DIR" -c http.extraHeader="Host: ${GITLAB_HOST}" \
		push -q --force "$(repo_url)" main
}

cmd_repo() {
	[ -d "$APP_DIR" ] || die "App directory not found: $APP_DIR"

	GITLAB_TOKEN="$(openssl rand -hex 20)"

	info "Creating access token..."
	create_token

	if project_exists; then
		info "Project '${GITLAB_PROJECT}' already exists."
	else
		info "Creating project '${GITLAB_PROJECT}'..."
		api projects -X POST -d "name=${GITLAB_PROJECT}" -d "visibility=public" >/dev/null
	fi

	info "Pushing application code..."
	push_code
	success "Repository ready: root/${GITLAB_PROJECT}"
}

# ---------- Main ----------
[ $# -eq 1 ] || usage

action="$1"

case "$1" in
	install)  cmd_install ;;
	password) cmd_password ;;
	status)   cmd_status ;;
	repo)     cmd_repo ;;
	*)        usage ;;
esac