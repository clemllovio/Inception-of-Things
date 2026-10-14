#!/bin/bash

set -e # Exec of the cripts stops if a commanf fail

GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

KUBECTL_VERSION="v1.31.0"

# Download vbox gpg key and install virtualbox
# curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --dearmor -o /etc/apt/keyrings/virtualbox.gpg
# echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/virtualbox.gpg] https://download.virtualbox.org/virtualbox/debian noble contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
# sudo apt update
# sudo apt install virtualbox-7.2 -y

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

# sudo apt install ca-certificates curl gnupg -y
# sudo install -m 0755 -d /etc/apt/keyrings
# sudo rm -f /etc/apt/keyrings/docker.gpg
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
# sudo chmod a+r /etc/apt/keyrings/docker.gpg
# echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu noble stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# sudo apt update
# sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
# sudo systemctl start docker
# sudo systemctl enable docker
# sudo usermod -aG docker ${USER}
# newgrp docker
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