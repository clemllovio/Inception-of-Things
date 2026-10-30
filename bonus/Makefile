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
# gitlab-deps: ## Deploy PostgreSQL, Valkey and Garage for GitLab
# 	@./scripts/dev_dependencies.sh setup
	
gitlab-install: install-postgres install-redis install-storage## Install GitLab with Helm
	@./scripts/gitlab.sh install

gitlab-status: ## Show GitLab status
	@./scripts/gitlab.sh status

gitlab-password: ## Print the GitLab root password
	@./scripts/gitlab.sh password

gitlab-repo: ## Create the GitLab project and push the app code
	@./scripts/gitlab.sh repo

install-postgres:
	@helm repo add bitnami https://charts.bitnami.com/bitnami
	@helm repo update
	@helm upgrade --install my-postgres bitnami/postgresql \
		--namespace gitlab \
		--set auth.database=gitlabhq_production \
		--set auth.username=gitlab \
		--set auth.password=password \
		--set primary.resourcesPreset=none \
		--set primary.resources.requests.memory=512Mi \
		--set primary.resources.limits.memory=2Gi \
		--set primary.extendedConfiguration="max_locks_per_transaction = 256" \
		--wait --timeout 5m

install-redis : #
	@helm install my-redis bitnami/redis \
		--namespace gitlab \
		--set auth.enabled=false

install-storage: # deploy minio for db storage
	@helm upgrade --install my-minio oci://registry-1.docker.io/bitnamicharts/minio \
		--namespace gitlab \
		--set auth.rootUser=minioadmin \
		--set auth.rootPassword=password \
		--set image.registry=docker.io \
		--set image.repository=bitnamilegacy/minio \
		--set console.image.registry=docker.io \
		--set console.image.repository=bitnamilegacy/minio-console \
		--set defaultBuckets="gitlab-registry\,gitlab-artifacts\,gitlab-lfs\,gitlab-uploads\,gitlab-packages" \
		--set volumePermissions.enabled=false \
		--set metrics.enabled=false \
		--set global.security.allowInsecureImages=true \
		--set console.enabled=false \
		--wait --timeout 5m

	@printf 'provider: AWS\nregion: us-east-1\naws_access_key_id: minioadmin\naws_secret_access_key: password\naws_signature_version: 4\nhost: my-minio.gitlab.svc.cluster.local\nendpoint: "http://my-minio.gitlab.svc.cluster.local:9000"\npath_style: true\n' | \
	kubectl create secret generic rails-storage-secret \
		--namespace gitlab \
		--from-file=connection=/dev/stdin \
		--dry-run=client -o yaml | kubectl apply -f -

	@printf 's3:\n  bucket: gitlab-registry\n  accesskey: minioadmin\n  secretkey: password\n  region: us-east-1\n  regionendpoint: http://my-minio.gitlab.svc.cluster.local:9000\n  v4auth: true\n  pathstyle: true\n' | \
	kubectl create secret generic registry-storage \
		--namespace gitlab \
		--from-file=connection=/dev/stdin \
		--dry-run=client -o yaml | kubectl apply -f -

# ======================= Ingress, hosts and app =====================
ingress-apply: ## Apply the Argo CD ingress
	@kubectl apply -f confs/ingress.yaml

app-apply:  ## Create the Argo CD Application (deploys the app in dev)
	@echo "Creating Argo CD Application..."
	@kubectl apply -f confs/application.yml
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
	hosts-add hosts-remove ingress-apply app-apply \
	clean fclean
# 	gitlab-deps gitlab-install gitlab-status gitlab-password \