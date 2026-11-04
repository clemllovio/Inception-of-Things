#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
	error "Usage: ${0##*/} {install|status|remove}"
	exit 1
}

install_postgres() {
	info "Installing PostgreSQL..."
	run_quiet helm repo add bitnami https://charts.bitnami.com/bitnami
	run_quiet helm repo update
	run_quiet helm upgrade --install my-postgres bitnami/postgresql \
		--namespace gitlab \
		--set auth.database=gitlabhq_production \
		--set auth.username=gitlab \
		--set auth.password=password \
		--set primary.resourcesPreset=none \
		--set primary.resources.requests.memory=512Mi \
		--set primary.resources.limits.memory=2Gi \
		--set primary.extendedConfiguration="max_locks_per_transaction = 256" \
		--wait --timeout 5m
}

install_redis() {
	info "Installing Redis..."
	run_quiet helm upgrade --install my-redis bitnami/redis \
		--namespace gitlab \
		--set auth.enabled=false
}

install_storage() {
	info "Installing MinIO..."
	run_quiet helm upgrade --install my-minio oci://registry-1.docker.io/bitnamicharts/minio \
		--namespace gitlab \
		--set auth.rootUser=minioadmin \
		--set auth.rootPassword=password \
		--set image.registry=docker.io \
		--set image.repository=bitnamilegacy/minio \
		--set console.image.registry=docker.io \
		--set console.image.repository=bitnamilegacy/minio-console \
		--set defaultBuckets="gitlab-registry\,gitlab-artifacts\,gitlab-lfs\,gitlab-uploads\,gitlab-packages" \
		--set volumePermissions.enabled=false \
		--set metrics.enabled=false \
		--set global.security.allowInsecureImages=true \
		--set console.enabled=false \
		--wait --timeout 5m

	info "Creating storage secrets..."
	printf 'provider: AWS\nregion: us-east-1\naws_access_key_id: minioadmin\naws_secret_access_key: password\naws_signature_version: 4\nhost: my-minio.gitlab.svc.cluster.local\nendpoint: "http://my-minio.gitlab.svc.cluster.local:9000"\npath_style: true\n' |
		kubectl create secret generic rails-storage-secret \
			--namespace gitlab \
			--from-file=connection=/dev/stdin \
			--dry-run=client -o yaml | kubectl apply -f - >/dev/null

	printf 's3:\n  bucket: gitlab-registry\n  accesskey: minioadmin\n  secretkey: password\n  region: us-east-1\n  regionendpoint: http://my-minio.gitlab.svc.cluster.local:9000\n  v4auth: true\n  pathstyle: true\n' |
		kubectl create secret generic registry-storage \
			--namespace gitlab \
			--from-file=connection=/dev/stdin \
			--dry-run=client -o yaml | kubectl apply -f - >/dev/null
}

cmd_install() {
	step "Installing GitLab dependencies"
	install_postgres
	install_redis
	install_storage
	success "GitLab dependencies are ready."
}

cmd_status() {
	helm list --namespace gitlab
	kubectl get pods --namespace gitlab
}

cmd_remove() {
	helm repo remove bitnami >/dev/null 2>&1 || true
	success "Helm repo bitnami removed."
}

# ---------- Main ----------
[ $# -eq 1 ] || usage

case "$1" in
	install)  cmd_install ;;
	status) cmd_status ;;
	remove) cmd_remove ;;
	*)      usage ;;
esac