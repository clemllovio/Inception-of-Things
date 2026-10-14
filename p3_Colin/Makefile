all: install clusters

install:
	sudo rm -f /etc/apt/sources.list.d/docker.list
	sudo rm -f /etc/apt/keyrings/virtualbox.gpg

	sudo apt update
	
	# Download and make kubectl executable
	curl -LO "https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl"
	chmod +x kubectl
	sudo mv kubectl /usr/local/bin/
	
	# Download and install k3d
	curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

	# Download vbox gpg key and install virtualbox
	curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --dearmor -o /etc/apt/keyrings/virtualbox.gpg
	echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/virtualbox.gpg] https://download.virtualbox.org/virtualbox/debian noble contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
	sudo apt update
	sudo apt install virtualbox-7.2 -y

	# Download docker gpg key and install docker and its dependencies
	sudo apt install ca-certificates curl gnupg -y
	sudo install -m 0755 -d /etc/apt/keyrings
	sudo rm -f /etc/apt/keyrings/docker.gpg
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
	sudo chmod a+r /etc/apt/keyrings/docker.gpg
	echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu noble stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt update
	sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
	sudo systemctl start docker
	sudo systemctl enable docker
	sudo usermod -aG docker ${USER}
	newgrp docker

	# Download and install argocd
	curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
	sudo install -m 555 argocd /usr/local/bin/argocd
	rm argocd

uninstall :
	sudo apt update
	sudo apt remove docker.io docker-doc docker-compose podman-docker containerd runc

clusters :
	k3d cluster create p3 --servers-memory 4G
	kubectl create namespace argocd
	kubectl create namespace dev
	kubectl apply --server-side --force-conflicts -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

launch :
	kubectl port-forward svc/argocd-server -n argocd 8080:443 

argocdpassword :
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

killclusters :
	docker system prune -a --volumes -f
	k3d cluster delete p3

	