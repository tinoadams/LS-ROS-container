SHELL := /bin/bash
PROJECT_NAME ?= ls-ros-container
GIT_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD | awk '{print tolower($$0)}')
GIT_HASH ?= $(shell git rev-parse --short HEAD | awk '{print tolower($$0)}')

# compose lowercase container tag and full name
CONTAINER_TAG ?= $(shell echo "$(GIT_BRANCH)-$(GIT_HASH)")
CONTAINER_NAME ?= $(shell echo "$(PROJECT_NAME):$(CONTAINER_TAG)")

.PHONY : help
help :
	@echo "Usage 'make [TARGET]', see list of targets below:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## Build and tag container
	docker build \
		-t "$(CONTAINER_NAME)" .
	@echo -e "\n\nUsage: make run RUN='$(CONTAINER_NAME)'"

run: RUN := $(or $(RUN),$(CONTAINER_NAME))
run: ## Run container for manual testing, optional "make run RUN='MYCONTAINER:TAG'"
	@[ "1000" == "`id -u`" ] || (echo "User ID on the host should match VSCode user id inside container"; exit 1)
	docker run -ti -a STDOUT -a STDERR \
		--mount type=bind,"source=$(PWD)","target=/workspace" \
		--mount source=/dev,target=/dev,type=bind \
		--mount source=$(HOME)/.ssh,target=/home/vscode/.ssh,type=bind,readonly \
		--mount source=/tmp/.X11-unix,target=/tmp/.X11-unix,type=bind \
		--workdir /workspace \
		-l vsch.quality=stable -l vsch.remote.devPort=0 -l vsch.local.folder="$(PWD)" \
		--privileged --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
		--env="DISPLAY=$(DISPLAY)" --env='QT_X11_NO_MITSHM=1' --gpus all \
		"$(RUN)"

release: ## Tag the current commit and push to origin in order for CI to build the image
	@[ -z "`git status --porcelain`" ] || (echo "Unable to publish with modified files in project"; exit 1)
	git tag -a $(CONTAINER_TAG) -m "Publishing container for build"
	git push origin "$(CONTAINER_TAG)"