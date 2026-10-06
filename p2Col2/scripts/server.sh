curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

mkdir -p /home/vagrant/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube/config
kubectl apply -f /vagrant/config/