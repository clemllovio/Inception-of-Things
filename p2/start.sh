#!/bin/bash

set -e

echo "Configuring hosts..."
./scripts/setup-hosts.sh

echo "Starting Vagrant..."
vagrant up