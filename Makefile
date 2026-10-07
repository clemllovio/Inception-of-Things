all: vagrant

vagrant:
	@if ! command -v vagrant >/dev/null 2>&1; then \
		echo "Installing vagrant..."; \
		wget -qO- https://apt.releases.hashicorp.com/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg; \
		echo "deb [arch=$$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $$(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null; \
		sudo apt-get update; \
		sudo apt-get install -y vagrant; \
	else \
		echo "Vagrant already installed."; \
	fi