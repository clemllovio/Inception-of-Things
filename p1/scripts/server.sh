#!/bin/bash

SERVER_IP="192.168.56.110"

# Install k3s
curl -sfL https://get.k3s.io -o k3s-install.sh
sh k3s-install.sh -s server --node-ip="${SERVER_IP}" \
  --advertise-address="${SERVER_IP}" \
  --flannel-iface=eth1

# Retrieve the token
TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)

# Store the token for the server worker
echo $TOKEN > /vagrant/token
