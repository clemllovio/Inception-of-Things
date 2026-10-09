GREEN   := \033[0;32m
RED     := \033[0;31m
RESET   := \033[0m

all: install version

# ===================== Prerequisite intallation ======================
install:
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "Installing Docker..."; \
		curl --progress-bar -fsSL https://get.docker.com -o get-docker.sh; \
		sudo sh get-docker.sh >/dev/null 2>&1; \
		rm -f get-docker.sh; \
		sudo usermod -aG docker $$USER >/dev/null 2>&1; \
	else \
		echo "Docker already installed."; \
	fi
	@if ! command -v kubectl >/dev/null 2>&1; then \
		echo "Installing kubectl..."; \
		curl -LO "https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl"; \
		chmod +x kubectl; \
		sudo mv kubectl /usr/local/bin/; \
	else \
		echo "kubectl already installed."; \
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
	@$(MAKE) --no-print-directory version

version:
	@which docker >/dev/null 2>&1 && echo "Docker :   $$(docker --version | awk '{print $$3}' | sed 's/,//')" || echo "$(RED)Docker :  [MISSING]$(RESET)"
	@which kubectl >/dev/null 2>&1 && echo "kubectl :  $$(kubectl version --client 2>/dev/null | grep -i 'Client Version' | awk '{print $$3}' || kubectl version --client --output=yaml 2>/dev/null | grep gitVersion | head -n 1 | awk '{print $$2}')" || echo "$(RED)kubectl : [MISSING]$(RESET)"
	@which k3d >/dev/null 2>&1 && echo "K3d :      $$(k3d version | head -n 1 | awk '{print $$3}')" || echo "$(RED)K3d :     [MISSING]$(RESET)"

# ============================== Cluster ==============================
create-cluster:
	@if k3d cluster list | grep -q "^iot"; then \
		echo "K3d cluster 'iot' already exists."; \
	else \
		echo "Creating K3d cluster (iot)..."; \
		k3d cluster create iot -p "8080:80@loadbalancer"; \
		echo "$(GREEN)Cluster 'iot' created successfully.$(RESET)"; \
	fi
	@$(MAKE) --no-print-directory check-cluster

check-cluster:
	@echo "$(GREEN)=== Kubernetes Node Status ===$(RESET)"
	@kubectl get nodes -o wide
	@echo "$(GREEN)=== K3d Cluster List ===$(RESET)"
	@k3d cluster list
	@echo "$(GREEN)=== Associated Docker Containers ===$(RESET)"
	@docker ps --filter "name=k3d-iot"

clean-cluster:
	@echo "Deleting K3d cluster (iot)..."
	@if k3d cluster list | grep -q "^iot"; then \
		k3d cluster delete iot; \
		echo "$(GREEN)Cluster 'iot' deleted successfully.$(RESET)"; \
	else \
		echo "No K3d cluster named 'iot' found."; \
	fi

# ============================= Namespaces ============================
create-namespaces:
	@if ! kubectl get namespace argocd >/dev/null 2>&1; then \
		echo "Creating argocd namespace..."; \
		kubectl create namespace argocd; \
	else \
		echo "Namespace argocd already exists."; \
	fi
	@if ! kubectl get namespace dev >/dev/null 2>&1; then \
		echo "Creating dev namespace..."; \
		kubectl create namespace dev; \
	else \
		echo "Namespace dev already exists."; \
	fi
	@echo "$(GREEN)Namespaces created successfully.$(RESET)"
	@$(MAKE) --no-print-directory check-namespaces

check-namespaces:
	@echo "$(GREEN)=== Namespaces list ===$(RESET)"
	@kubectl get namespaces

# ========================= Argocd deployment =========================
deploy-argocd:
	@echo "Deploying Argocd on argocd namespace..."
	@kubectl apply --server-side --force-conflicts -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@kubectl rollout status deployment/argocd-server -n argocd --timeout=120s
	@kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge -p '{"data":{"server.insecure":"true"}}'
	@kubectl rollout restart deployment argocd-server -n argocd
	@kubectl rollout status deployment/argocd-server -n argocd --timeout=120s

argocd-password:
	@echo "Retrieving admin password..."
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

apply-ingress-confs:
	@kubectl apply -f confs/ingress.yaml
	@grep -q "argocd.local" /etc/hosts || echo "127.0.0.1 argocd.local app.local" | sudo tee -a /etc/hosts

apply-conf-application:
	@kubectl apply -f confs/application.yaml
	
# ============================== Clean ===============================
clean: clean-cluster clean-hosts
	@rm -f get-docker.sh install_k3d.sh kubectl
	@echo "$(GREEN)Clean done.$(RESET)"

clean-hosts:
	@echo "Cleaning /etc/hosts..."
	@sudo sed -i '/argocd\.local/d' /etc/hosts

# Delete all software installed except docker
fclean: clean
	@echo "Removing kubectl and k3d..."
	@sudo rm -f /usr/local/bin/kubectl /usr/local/bin/k3d
	@echo "$(GREEN)Full clean done.$(RESET)"

.PHONY: all install version create-cluster check-cluster clean-cluster create-namespaces check-namespaces deploy-argocd argocd-password apply-ingress-confs clean clean-hosts fclean