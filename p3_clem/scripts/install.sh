#!/bin/bash

set -e # Exec of the cripts stops if a commanf fail

GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

KUBECTL_VERSION="v1.31.0"

# ----------------------------- Docker ------------------------------
if ! command -v docker >/dev/null 2>&1; then
	echo "Installing Docker..."
	curl -fsSL https://get.docker.com -o "$TMP_DIR/get-docker.sh"
	sudo sh "$TMP_DIR/get-docker.sh" >/dev/null 2>&1
	sudo usermod -aG docker "$USER"
	echo "Docker installed."
else
	echo "Docker already installed."
fi

# ----------------------------- kubectl -----------------------------
if ! command -v kubectl >/dev/null 2>&1; then
	echo "Installing kubectl..."
	curl -fsSL -o "$TMP_DIR/kubectl" \
		"https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
	chmod +x "$TMP_DIR/kubectl"
	sudo mv "$TMP_DIR/kubectl" /usr/local/bin/kubectl
else
	echo "kubectl already installed."
fi

# ------------------------------- k3d -------------------------------
if ! command -v k3d >/dev/null 2>&1; then
	echo "Installing K3d..."
	curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh -o "$TMP_DIR/install_k3d.sh"
	bash "$TMP_DIR/install_k3d.sh" >/dev/null 2>&1
else
	echo "K3d already installed."
fi

echo -e "${GREEN}All dependencies installed successfully.${RESET}"