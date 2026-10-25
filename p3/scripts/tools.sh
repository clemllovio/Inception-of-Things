#!/bin/bash

set -e # Exec of the cripts stops if a commanf fail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

readonly KUBECTL_VERSION="${KUBECTL_VERSION:-v1.31.0}"
TMP_DIR=""

cleanup() {
	[ -z "$TMP_DIR" ] || rm -rf "$TMP_DIR"
}

usage() {
	error "Usage: ${0##*/} {install|version|uninstall}"
	exit 1
}

# ---------- version ----------
docker_version() {
	docker --version | awk '{print $3}' | sed 's/,//'
}

kubectl_version() {
	kubectl version --client --output=yaml 2>/dev/null | awk '/gitVersion/ {print $2; exit}'
}

k3d_version() {
	k3d version | head -n 1 | awk '{print $$3}'
}

print_version() {
	local name="$1"
	local version_fn="$2"

	if command -v "$name" >/dev/null 2>&1; then
		info "${name}: $("$version_fn" || echo "unknown")"
	else
		error "${name}: [MISSING]"
	fi
}

cmd_version() {
	print_version docker  docker_version
	print_version kubectl kubectl_version
	print_version k3d     k3d_version
}

# ---------- install ----------
install_docker() {
	info "Installing Docker..."
	curl -fsSL https://get.docker.com -o "$TMP_DIR/get-docker.sh"
	sudo sh "$TMP_DIR/get-docker.sh" >/dev/null 2>&1
	sudo systemctl start docker
	sudo systemctl enable docker
	sudo usermod -aG docker ${USER}
	success "Docker installed."
}

install_kubectl() {
	info "Installing kubectl..."
	curl -fsSL -o "$TMP_DIR/kubectl" \
		"https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
	chmod +x "$TMP_DIR/kubectl"
	sudo mv "$TMP_DIR/kubectl" /usr/local/bin/kubectl
	success "kubectl installed."
}

install_k3d() {
	info "Installing K3d..."
	curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh \
		-o "$TMP_DIR/install_k3d.sh"
	bash "$TMP_DIR/install_k3d.sh" >/dev/null 2>&1
	success "K3d installed."
}

install_if_missing() {
	local name="$1"
	local install_function="$2"

	if command -v "$name" >/dev/null 2>&1; then
		info "$name already installed."
	else
		"$install_function"
	fi
}

cmd_install() {
	TMP_DIR="$(mktemp -d)"
	trap cleanup EXIT

	install_if_missing docker  install_docker
	install_if_missing kubectl install_kubectl
	install_if_missing k3d     install_k3d

	success "All dependencies installed successfully."
}

# ---------- uninstall ----------

cmd_uninstall() {
	info "Removing kubectl and k3d..."
	sudo rm -f /usr/local/bin/kubectl /usr/local/bin/k3d
	success "kubectl and k3d removed (docker kept)."
}

[ $# -eq 1 ] || usage

action="$1"

case "$action" in
	install)   cmd_install ;;
	version)   cmd_version ;;
	uninstall) cmd_uninstall ;;
	*)         usage ;;
esac