# ============================ Variables =============================
CLUSTER    := iot
NAMESPACES := argocd dev
HOSTS      := argocd.local app.local
ARGOCD_URL := https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
.DEFAULT_GOAL := help

GREEN   := \033[0;32m
RED     := \033[0;31m
RESET   := \033[0m

# ============================== Main ================================
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "} {printf "  %-24s %s\n", $$1, $$2}'

all: install up  ## Install tools and deploy everything

up: create-cluster create-namespaces deploy-argocd apply-ingress-confs apply-conf-application ## Deploy the whole stack

re: clean up ## Delete everything and redeploy

# ===================== Prerequisite intallation ======================
install:  ## Install docker, kubectl and k3d
	@chmod +x scripts/install.sh
	@./scripts/install.sh
	@$(MAKE) --no-print-directory version

version:  ## Show installed tool versions
	@which docker >/dev/null 2>&1 && echo "Docker :   $$(docker --version | awk '{print $$3}' | sed 's/,//')" || echo "$(RED)Docker :  [MISSING]$(RESET)"
	@which kubectl >/dev/null 2>&1 && echo "kubectl :  $$(kubectl version --client 2>/dev/null | grep -i 'Client Version' | awk '{print $$3}' || kubectl version --client --output=yaml 2>/dev/null | grep gitVersion | head -n 1 | awk '{print $$2}')" || echo "$(RED)kubectl : [MISSING]$(RESET)"
	@which k3d >/dev/null 2>&1 && echo "K3d :      $$(k3d version | head -n 1 | awk '{print $$3}')" || echo "$(RED)K3d :     [MISSING]$(RESET)"

# ============================== Cluster ==============================
create-cluster:  ## Create the k3d cluster
	@if k3d cluster  get $(CLUSTER) >/dev/null 2>&1; then \
		echo "Cluster '$(CLUSTER)' already exists."; \
	else \
		echo "Creating cluster '$(CLUSTER)'..."; \
		k3d cluster create iot -p "8080:80@loadbalancer"; \
		echo "$(GREEN)Cluster '$(CLUSTER)' created successfully.$(RESET)"; \
	fi
	@$(MAKE) --no-print-directory check-cluster

check-cluster: ## Show cluster status
	@echo "$(GREEN)=== Kubernetes Node Status ===$(RESET)"
	@kubectl get nodes -o wide
	@echo "$(GREEN)=== K3d Cluster List ===$(RESET)"
	@k3d cluster list
	@echo "$(GREEN)=== Associated Docker Containers ===$(RESET)"
	@docker ps --filter "name=k3d-$(CLUSTER)"

# ============================= Namespaces ============================
create-namespaces: ## Create argocd and dev namespaces
	@for ns in $(NAMESPACES); do \
		if kubectl get namespace $$ns >/dev/null 2>&1; then \
			echo "Namespace '$$ns' already exists."; \
		else \
			echo "Creating namespace '$$ns'..."; \
			kubectl create namespace $$ns; \
		fi; \
	done
	@echo "$(GREEN)Namespaces created successfully.$(RESET)"
	@$(MAKE) --no-print-directory check-namespaces

check-namespaces:
	@echo "$(GREEN)=== Namespaces list ===$(RESET)"
	@kubectl get namespaces

# ========================= Argocd deployment =========================
deploy-argocd: ## Install Argo CD (insecure mode for the ingress)
	@echo "Deploying Argo CD in namespace 'argocd'..."
	@kubectl apply --server-side --force-conflicts -n argocd -f  $(ARGOCD_URL)
	@echo "Waiting for Argo CD server to be ready..."
	@kubectl rollout status deployment/argocd-server -n argocd --timeout=120s
	@echo "Enabling insecure mode (TLS handled by the ingress)..."
	@kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge -p '{"data":{"server.insecure":"true"}}'
	@kubectl rollout restart deployment argocd-server -n argocd
	@echo "Waiting for Argo CD server to restart..."
	@kubectl rollout status deployment/argocd-server -n argocd --timeout=120s
	@echo "$(GREEN)Argo CD deployed successfully.$(RESET)"

argocd-password: ## Print the Argo CD admin password
	@printf "Argo CD admin password: "
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo 

apply-ingress-confs: ## Apply the Argo CD ingress and update /etc/hosts
	@echo "Applying Argo CD ingress..."
	@kubectl apply -f confs/ingress.yaml
	@for h in $(HOSTS); do \
		if grep -qw "$$h" /etc/hosts; then \
			echo "$$h already in /etc/hosts."; \
		else \
			echo "Adding $$h to /etc/hosts..."; \
			echo "127.0.0.1 $$h" | sudo tee -a /etc/hosts >/dev/null; \
		fi; \
	done
	@printf "$(GREEN)Ingress configured:$(RESET)\n"
	@printf "  Argo CD : http://argocd.local:8080\n"
	@printf "  App     : http://app.local:8080\n"

apply-conf-application:  ## Create the Argo CD Application (deploys the app in dev)
	@echo "Creating Argo CD Application..."
	@kubectl apply -f confs/application.yaml
	@echo "$(GREEN)Application created. Argo CD will now sync the app into 'dev'.$(RESET)"
	
# ============================== Clean ===============================
clean: clean-cluster clean-hosts ## Delete the cluster and the hosts entries
	@printf "$(GREEN)Clean done.$(RESET)\n"

clean-cluster:
	@echo "Deleting K3d cluster '$(CLUSTER)'..."
	@if k3d cluster get $(CLUSTER) >/dev/null 2>&1; then \
		k3d cluster delete $(CLUSTER); \
		printf "$(GREEN)Cluster '$(CLUSTER)' deleted successfully.$(RESET)\n"; \
	else \
		echo "No cluster '$(CLUSTER)' found."; \
	fi

clean-hosts:
	@echo "Cleaning /etc/hosts..."
	@for h in $(HOSTS); do \
		if grep -qw "$$h" /etc/hosts; then \
			echo "Removing $$h from /etc/hosts..."; \
			sudo sed -i "/$$h/d" /etc/hosts; \
		else \
			echo "$$h not in /etc/hosts."; \
		fi; \
	done

fclean: clean ## Also remove kubectl and k3d (keeps docker)
	@echo "Removing kubectl and k3d..."
	@sudo rm -f /usr/local/bin/kubectl /usr/local/bin/k3d
	@printf "$(GREEN)Full clean done.$(RESET)\n"

.PHONY: help all up re install version create-cluster check-cluster \
	create-namespaces deploy-argocd argocd-password apply-ingress-confs \
	apply-conf-application clean clean-cluster clean-hosts fclean