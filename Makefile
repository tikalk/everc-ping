#!/usr/bin/make -f

# DOCKER_USERNAME:= hagzag
# REPO:= docker.io
# REGISTRY := $(REPO)/$(DOCKER_USERNAME)

DOCKER_COMPOSE := /usr/local/bin/docker-compose
REDIS_PASSWORD := 'MyS3cr3t'

RELEASE_NAME	 := ping-app
CHART_BASE_DIR := ./deployment/helm/charts
CHART_NAME		 := pingalicious

.PHONY: k3d-devcluster k3d-cleanup-cluster dc-build dc-push dc-stop dc-clean-run dc-run
.PHONY: docker-check redis-container-start redis-container-stop redis-container-cleanup node-cleanup node-npm-install node-run-local 

# k3d crete devcluster
k3d-devcluster:
	@k3d cluster create devcluster \
	--api-port 127.0.0.1:6443 \
	-p 80:80@loadbalancer \
	-p 443:443@loadbalancer

k3d-cleanup-cluster:
	@k3d cluster delete devcluster

# helm labs

helm-dependency-build:	## helm-chart :: dependency build
	@rm -f $(CHART_BASE_DIR)/$(CHART_NAME)/Chart.lock ; \
	helm dependency build $(CHART_BASE_DIR)/$(CHART_NAME)

helm-install-chart: helm-dependency-build ## helm-install-source: helm upgrade $(CHART_NAME)-dev --install
	@helm upgrade $(RELEASE_NAME)-dev --install $(CHART_BASE_DIR)/$(CHART_NAME)

helm-install-chart-init: ## helm-install-source: helm upgrade $(CHART_NAME)-dev --install
	@echo "Please note this install is without ingress !"
	@helm upgrade $(RELEASE_NAME)-dev --install -f $(CHART_BASE_DIR)/$(CHART_NAME)/values-init-version.yaml $(CHART_BASE_DIR)/$(CHART_NAME)

helm-cleanup-chart-release:
	@helm uninstall $(RELEASE_NAME)-dev

helm-get-values:										## helm-get-values: helm get values $(CHART_NAME)-dev 
	@helm get values $(RELEASE_NAME)-dev

helm-get-manifest:									## helm-get-manifest: helm get manifest $(CHART_NAME)-dev 
	@helm get manifest $(RELEASE_NAME)-dev

# kustomize labs

ping-kustomize-deploy:
	@kubectl apply -k ./deployment/kustomize/manifests

ping-kustomize-deploy-ingress:
	@kubectl apply -k ./deployment/kustomize/ingress

ping-kustomize-deploy-configs:
	@kubectl apply -k ./deployment/kustomize/configs

ping-kustomize-deploy-initContainers:
	@kubectl apply -k ./deployment/kustomize/initContainers

# node-* run nodejs local 
docker-check:
	@docker ps &>/dev/null || echo "docker not running"

redis-container-start: docker-check
	@docker ps | grep redis || \
	 docker run -d --name redis -p 6379:6379 redis redis-server --requirepass $(REDIS_PASSWORD)  && \
	 docker ps | grep redis

redis-container-stop: docker-check
	@docker stop redis

redis-container-cleanup:
	@docker rm -f redis


# node-* run nodejs local 

node-cleanup:
	@rm -rf ./src/api/node_modules

node-npm-install:
	@cd ./src/api && npm install

node-run-local: node-npm-install redis-container-start
	@cd ./src/api && npm start

# dc-* docker-compose

dc-build: 
	$(DOCKER_COMPOSE) build

dc-run: | dc-stop
	$(DOCKER_COMPOSE) up -d

dc-stop:
	$(DOCKER_COMPOSE) down

dc-run-clean: | dc-stop dc-build dc-run

# remove volumes !
dc-clean:
	$(DOCKER_COMPOSE) down --rmi local

# pushed to whatever the image: <repo>/<name> is set to ...
dc-push: 
	$(DOCKER_COMPOSE) push
