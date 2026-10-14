# Install k3s
curl -sfL https://get.k3s.io | sh -

# Retrieve the token
TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)

# Store the token for the server worker
echo $TOKEN > /vagrant/token