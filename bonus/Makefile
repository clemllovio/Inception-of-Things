# ============================ Variables =============================
include config.env
export HOSTS_FILE HOSTS_IP HTTP_PORT

CLUSTER    := iot
NAMESPACES := argocd dev
HOSTS      := argocd.local app.local gitlab.local

LOG := ./scripts/log.sh

.DEFAULT_GOAL := help

# ============================== Main ================================
help: ## Show this help
	@grep -hE '^[a-zA-Z0-9_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "} {printf "  %-24s %s\n", $$1, $$2}'

all: tools-install up  ## Install tools and deploy everything

up: cluster-create namespaces-create argocd-install gitlab-install gitlab-repo ingress-apply app-apply hosts-add ## Deploy the whole stack

re: clean up ## Delete everything and redeploy

# ============================== Tools ===============================
tools-install: ## Install docker, kubectl, k3d and helm
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

# ============================== GitLab ==============================
gitlab-deps: ## Deploy PostgreSQL, Valkey and Garage for GitLab
	@./scripts/dev_dependencies.sh setup

gitlab-deps-status: ## Show GitLab dependencies status
	@./scripts/dev_dependencies.sh status

gitlab-deps-clean: ## Remove GitLab dependencies (keeps the cluster)
	@./scripts/dev_dependencies.sh teardown
	
gitlab-install: gitlab-deps ## Install GitLab with Helm
	@./scripts/gitlab.sh install

gitlab-status: ## Show GitLab status
	@./scripts/gitlab.sh status

gitlab-password: ## Print the GitLab root password
	@./scripts/gitlab.sh password

gitlab-repo: ## Create the GitLab project and push the app code
	@./scripts/gitlab.sh repo

# ======================= Ingress, hosts and app =====================
ingress-apply: ## Apply the Argo CD ingress
	@kubectl apply -f confs/ingress.yaml

app-apply:  ## Create the Argo CD Application (deploys the app in dev)
	@echo "Creating Argo CD Application..."
	@kubectl apply -f confs/application.yaml
	@$(LOG) success "Application created. Argo CD will now sync the app into 'dev'."
	
hosts-add: ## Add the local hosts to /etc/hosts
	@./scripts/hosts.sh add $(HOSTS)
	@$(LOG) success "Hosts configured, services available at:"
	@for h in $(HOSTS); do $(LOG) info "  http://$$h:$(HTTP_PORT)"; done

hosts-remove:
	@echo "Cleaning /etc/hosts..."
	@./scripts/hosts.sh remove $(HOSTS)

urls: ## Show the service URLs
	@$(LOG) success "Services available at:"
	@for h in $(HOSTS); do $(LOG) info "  http://$$h:$(HTTP_PORT)"; done

# ============================== Clean ===============================
clean: cluster-delete hosts-remove ## Delete the cluster and the hosts entries
	@$(LOG) success "Clean done."

cluster-delete:
	@./scripts/cluster.sh delete $(CLUSTER)

fclean: clean ## Also remove kubectl and k3d (keeps docker)
	@./scripts/tools.sh uninstall
	@$(LOG) success "Full clean done."

# ============================= Phony ================================
.PHONY: help all up re \
	tools-install tools-version \
	cluster-create cluster-status cluster-delete \
	namespaces-create namespaces-status \
	argocd-install argocd-password \
	gitlab-deps gitlab-install gitlab-status gitlab-password \
	hosts-add hosts-remove ingress-apply app-apply \
	clean fclean