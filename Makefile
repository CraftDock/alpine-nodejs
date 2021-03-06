## Meta data about the image
DOCKER_IMAGE=dsuite/alpine-nodejs
DOCKER_IMAGE_CREATED=$(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
DOCKER_IMAGE_REVISION=$(shell git rev-parse --short HEAD)

## Current directory
DIR:=$(strip $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))))

## Define the latest version
latest=16
lts=14
current=16

## Config
.DEFAULT_GOAL := help
.PHONY: *

help: ## This help!
	@printf "\033[33mUsage:\033[0m\n  make [target] [arg=\"val\"...]\n\n\033[33mTargets:\033[0m\n"
	@grep -E '^[-a-zA-Z0-9_\.\/]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-15s\033[0m %s\n", $$1, $$2}'

build-all: ## Build all supported versions
	@$(MAKE) build v=10
	@$(MAKE) build v=11
	@$(MAKE) build v=12
	@$(MAKE) build v=13
	@$(MAKE) build v=14
	@$(MAKE) build v=15
	@$(MAKE) build v=16

test-all: ## Build all supported versions
	@$(MAKE) test v=10
	@$(MAKE) test v=11
	@$(MAKE) test v=12
	@$(MAKE) test v=13
	@$(MAKE) test v=14
	@$(MAKE) test v=15
	@$(MAKE) test v=16

push-all: ## Push all supported versions
	@$(MAKE) push v=10
	@$(MAKE) push v=11
	@$(MAKE) push v=12
	@$(MAKE) push v=13
	@$(MAKE) push v=14
	@$(MAKE) push v=15
	@$(MAKE) push v=16

build: ## Build ( usage : make build v=14 )
	$(eval version := $(or $(v),$(latest)))
	@docker run --rm \
		-e NODE_VERSION=$(version) \
		-e DOCKER_IMAGE_CREATED=$(DOCKER_IMAGE_CREATED) \
		-e DOCKER_IMAGE_REVISION=$(DOCKER_IMAGE_REVISION) \
		-v $(DIR)/Dockerfiles:/data \
		dsuite/alpine-data \
		sh -c "templater Dockerfile.template > Dockerfile-$(version)"
	@docker build --force-rm \
		--build-arg GH_TOKEN=${GH_TOKEN} \
		--file $(DIR)/Dockerfiles/Dockerfile-$(version) \
		--tag $(DOCKER_IMAGE):$(version) \
		$(DIR)/Dockerfiles
	@[ "$(version)" = "$(lts)" ] && docker tag $(DOCKER_IMAGE):$(version) $(DOCKER_IMAGE):lts || true
	@[ "$(version)" = "$(current)" ] && docker tag $(DOCKER_IMAGE):$(version) $(DOCKER_IMAGE):current || true
	@[ "$(version)" = "$(latest)" ] && docker tag $(DOCKER_IMAGE):$(version) $(DOCKER_IMAGE):latest || true

test: ## Test ( usage : make test v=14 )
	$(eval version := $(or $(v),$(latest)))
	@GOSS_FILES_PATH=$(DIR)/tests \
	GOSS_SLEEP=0.5 \
	 	dgoss run $(DOCKER_IMAGE):$(version)

push: ## Push ( usage : make push v=14 )
	$(eval version := $(or $(v),$(latest)))
	@docker push $(DOCKER_IMAGE):$(version)
	@[ "$(version)" = "$(lts)" ] && docker push $(DOCKER_IMAGE):lts || true
	@[ "$(version)" = "$(current)" ] && docker push $(DOCKER_IMAGE):current || true
	@[ "$(version)" = "$(latest)" ] && docker push $(DOCKER_IMAGE):latest || true

shell: ## Run shell ( usage : make shell v=14 )
	$(eval version := $(or $(v),$(latest)))
	@docker run -it --rm \
		-e DEBUG_LEVEL=DEBUG \
		$(DOCKER_IMAGE):$(version) \
		bash

remove: ## Remove all generated images
	@docker images | grep $(DOCKER_IMAGE) | tr -s ' ' | cut -d ' ' -f 2 | xargs -I {} docker rmi $(DOCKER_IMAGE):{} || true
	@docker images | grep $(DOCKER_IMAGE) | tr -s ' ' | cut -d ' ' -f 3 | xargs -I {} docker rmi {} || true

readme: ## Generate docker hub full description
	@docker run -t --rm \
		-e DOCKER_USERNAME=${DOCKER_USERNAME} \
		-e DOCKER_PASSWORD=${DOCKER_PASSWORD} \
		-e DOCKER_IMAGE=${DOCKER_IMAGE} \
		-v $(DIR):/data \
		dsuite/hub-updater


