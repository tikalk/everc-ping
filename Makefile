#!/usr/bin/make -f

# DOCKER_USERNAME:= hagzag
# REPO:= docker.io
# REGISTRY := $(REPO)/$(DOCKER_USERNAME)

DOCKER_COMPOSE := /usr/local/bin/docker-compose
REDIS_PASSWORD := 'MyS3cr3t'

.PHONY: docker-check redis-container-start redis-container-stop redis-container-cleanup node-cleanup node-npm-install node-run-local 

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
