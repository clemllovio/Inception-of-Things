# ============================ Variables =============================
include config.env
export HOSTS_FILE HOSTS_IP HTTP_PORT

CLUSTER    := iot
NAMESPACES := argocd dev gitlab
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

tools-version:  ## Show installed tool versions
	@./scripts/tools.sh version

# ============================== Cluster ==============================
cluster-create:  ## Create the k3d cluster
	@./scripts/cluster.sh create $(CLUSTER)

cluster-status: ## Show cluster status
	@./scripts/cluster.sh status $(CLUSTER)

# ============================= Namespaces ============================
namespaces-create: ## Create argocd, dev and gitlab namespaces
	@./scripts/namespaces.sh create $(NAMESPACES)

namespaces-status: ## Show the namespaces
	@./scripts/namespaces.sh status

# ============================== Argo CD =============================
argocd-install: ## Install Argo CD (insecure mode for the ingress)
	@./scripts/argocd.sh install

argocd-password: ## Print the Argo CD admin password
	@./scripts/argocd.sh password

# ============================== GitLab ==============================
gitlab-deps: ## Deploy PostgreSQL, Redis and MinIO for GitLab
	@./scripts/gitlab_deps.sh install

gitlab-deps-status: ## Show GitLab dependencies status
	@./scripts/gitlab_deps.sh status
	
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
	@$(LOG) step "Applying ingress"
	@kubectl apply -f confs/ingress.yaml >/dev/null
	@$(LOG) success "Ingress applied."

app-apply:  ## Create the Argo CD Application (deploys the app in dev)
	@$(LOG) step "Creating Argo CD application"
	@kubectl apply -f confs/application.yml >/dev/null
	@$(LOG) success "Application created. Argo CD will now sync the app into 'dev'."
	
hosts-add: ## Add the local hosts to /etc/hosts
	@$(LOG) step "Configuring /etc/hosts"
	@./scripts/hosts.sh add $(HOSTS)
	@$(LOG) success "Hosts configured, services available at:"
	@for h in $(HOSTS); do $(LOG) info "  http://$$h:$(HTTP_PORT)"; done


urls: ## Show the service URLs
	@$(LOG) success "Services available at:"
	@for h in $(HOSTS); do $(LOG) info "  http://$$h:$(HTTP_PORT)"; done

# ============================== Clean ===============================
clean: cluster-delete hosts-remove helm-repo-remove ## Delete the cluster, the hosts entries and the Bitnami Helm repo
	@$(LOG) success "Clean done."

cluster-delete: ## Delete the k3d cluster
	@$(LOG) step "Deleting cluster '$(CLUSTER)'"
	@./scripts/cluster.sh delete $(CLUSTER)

hosts-remove: ## Remove the local hosts from /etc/hosts
	@$(LOG) step "Removing hosts entries"
	@./scripts/hosts.sh remove $(HOSTS)

helm-repo-remove: ## Remove the Bitnami Helm repo
	@$(LOG) step "Removing Helm repo bitnami"
	@./scripts/gitlab_deps.sh remove

fclean: clean ## Also remove kubectl, k3d and helm (keeps docker)
	@./scripts/tools.sh uninstall
	@$(LOG) success "Full clean done."

# ============================= Phony ================================
.PHONY: help all up re \
	tools-install tools-version \
	cluster-create cluster-status \
	namespaces-create namespaces-status \
	argocd-install argocd-password \
	gitlab-deps gitlab-deps-status gitlab-install gitlab-status gitlab-password gitlab-repo \
	hosts-add ingress-apply app-apply \
	clean cluster-delete hosts-remove helm-repo-remove fclean