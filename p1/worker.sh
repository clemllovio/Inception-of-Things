#!/bin/bash

SERVER_IP=$1
WORKER_IP="192.168.56.111"
TOKEN=$(cat /vagrant/token)

curl -sfL https://get.k3s.io -o k3s-install.sh
K3S_URL=https://${SERVER_IP}:6443 K3S_TOKEN=${TOKEN} sh k3s-install.sh