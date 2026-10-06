GREEN   := \033[0;32m
RED     := \033[0;31m
RESET   := \033[0m

all: setup check

install: setup check

setup:
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "Installing Docker..."; \
		curl --progress-bar -fsSL https://get.docker.com -o get-docker.sh; \
		sudo sh get-docker.sh >/dev/null 2>&1; \
		rm -f get-docker.sh; \
		sudo usermod -aG docker $$USER >/dev/null 2>&1; \
	else \
		echo "Docker already installed."; \
	fi
	@if ! command -v k3d >/dev/null 2>&1; then \
		echo "Installing K3d..."; \
		curl --progress-bar -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh -o install_k3d.sh; \
		bash install_k3d.sh >/dev/null 2>&1; \
		rm -f install_k3d.sh; \
	else \
		echo "K3d already installed."; \
	fi
	@echo "$(GREEN)All dependencies installed successfully.$(RESET)"

check:
	@which docker >/dev/null 2>&1 && echo "Docker :   $$(docker --version)" || echo "$(RED)Docker :  [MISSING]$(RESET)"
	@which k3d >/dev/null 2>&1 && echo "K3d :      $$(k3d version | head -n 1)" || echo "$(RED)K3d :     [MISSING]$(RESET)"

.PHONY: all setup check