#!/bin/bash

set -e

IP="192.168.56.110"
HOSTS="app1.com app2.com app3.com"

echo "192.168.56.110 app1.com app2.com app3.com" | sudo tee -a /etc/hosts

if ! grep -qF "$IP $HOSTS" /etc/hosts; then
    echo "$IP $HOSTS" | sudo tee -a /etc/hosts
    echo "Entries added to /etc/hosts."
else
    echo "Entries already exist in /etc/hosts."
fi