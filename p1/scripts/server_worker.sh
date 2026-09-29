#!/bin/bash

# Get server IP from the arguments
SERVER_IP=$1
WORKER_IP="192.168.56.111"

# Get the token from the shared folder
TOKEN=$(cat /vagrant/token)

curl -sfL https://get.k3s.io -o k3s-install.sh

K3S_URL=https://${SERVER_IP}:6443 K3S_TOKEN=${TOKEN} sh k3s-install.sh agent \
  --node-ip="${WORKER_IP}" \
  --flannel-iface=eth1 \
  --node-label "node.kubernetes.io/type=worker"