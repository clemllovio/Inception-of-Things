# ============================ Variables =============================
include config.env
export HOSTS_FILE HOSTS_IP HTTP_PORT

CLUSTER    := iot
NAMESPACES := argocd dev
HOSTS      := argocd.local app.local

LOG := ./scripts/log.sh

.DEFAULT_GOAL := help

# ============================== Main ================================
help: ## Show this help
	@grep -hE '^[a-zA-Z0-9_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "} {printf "  %-24s %s\n", $$1, $$2}'

all: tools-install up  ## Install tools and deploy everything

up: cluster-create namespaces-create argocd-install ingress-apply app-apply hosts-add ## Deploy the whole stack

re: clean up ## Delete everything and redeploy

# ============================== Tools ===============================
tools-install: ## Install docker, kubectl and k3d
	@./scripts/tools.sh install
	@./scripts/tools.sh version

tools-version:  ## Show installed tool versions
	@./scripts/tools.sh version

# ============================== Cluster ==============================
cluster-create:  ## Create the k3d cluster
	@./scripts/cluster.sh create $(CLUSTER)

cluster-status: ## Show cluster status
	@./scripts/cluster.sh status $(CLUSTER)

# ============================= Namespaces ============================
namespaces-create: ## Create argocd and dev namespaces
	@./scripts/namespaces.sh create $(NAMESPACES)

namespaces-status:
	@./scripts/namespaces.sh status

# ============================== Argo CD =============================
argocd-install: ## Install Argo CD (insecure mode for the ingress)
	@./scripts/argocd.sh install

argocd-password: ## Print the Argo CD admin password
	@./scripts/argocd.sh password

# ======================= Ingress, hosts and app =====================
hosts-add: ## Add the local hosts to /etc/hosts
	@./scripts/hosts.sh add $(HOSTS)
	@$(LOG) success "Hosts configured, services available at:"
	@for h in $(HOSTS); do $(LOG) info "  http://$$h:$(HTTP_PORT)"; done

ingress-apply: ## Apply the Argo CD ingress
	@kubectl apply -f confs/ingress.yaml

app-apply:  ## Create the Argo CD Application (deploys the app in dev)
	@echo "Creating Argo CD Application..."
	@kubectl apply -f confs/application.yaml
	@$(LOG) success "Application created. Argo CD will now sync the app into 'dev'."
	
# ============================== Clean ===============================
clean: cluster-delete hosts-remove ## Delete the cluster and the hosts entries
	@$(LOG) success "Clean done."

cluster-delete:
	@./scripts/cluster.sh delete $(CLUSTER)

hosts-remove:
	@echo "Cleaning /etc/hosts..."
	@./scripts/hosts.sh remove $(HOSTS)

fclean: clean ## Also remove kubectl and k3d (keeps docker)
	@./scripts/tools.sh uninstall
	@$(LOG) success "Full clean done."

# ============================= Phony ================================
.PHONY: help all up re \
	tools-install tools-version \
	cluster-create cluster-status cluster-delete \
	namespaces-create namespaces-status \
	argocd-install argocd-password \
	hosts-add hosts-remove ingress-apply app-apply \
	clean fclean