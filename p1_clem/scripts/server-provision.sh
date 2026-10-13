#!/bin/bash

SERVER_IP=$1

# Install k3s
curl -sfL https://get.k3s.io -o k3s-install.sh
sh k3s-install.sh -s server --node-ip="${SERVER_IP}"

# Retrieve the token
TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)

# Store the token for the server worker
echo $TOKEN > /vagrant/token