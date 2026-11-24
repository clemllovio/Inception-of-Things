#!/bin/bash

SERVER_IP=$1

# Install k3s
curl -sfL https://get.k3s.io -o k3s-install.sh
sh  k3s-install.sh -s server --node-ip="${SERVER_IP}"

# Apply all YAML files
sudo kubectl apply -f /vagrant/confs

# Waiting for all the pods to be ready
sudo kubectl rollout status deployment/app-one --timeout=120s
sudo kubectl rollout status deployment/app-two --timeout=120s
sudo kubectl rollout status deployment/app-three --timeout=120s