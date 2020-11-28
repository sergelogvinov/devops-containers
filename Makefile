#

THIS_FILE:=$(lastword $(MAKEFILE_LIST))
BUILD_VCS_BRANCH?=$(shell git branch 2>/dev/null | sed -n '/^\*/s/^\* //p' | sed 's/\//-/g' | sed 's/^(HEAD detached at \(.*\))$$/\1/g')
BUILD_VCS_NUMBER?=$(shell git rev-parse --short=7 HEAD)
CODE_TAG?=$(shell git describe --exact-match --tags 2>/dev/null || git branch 2>/dev/null | sed -n '/^\*/s/^\* //p' | sed 's/\//-/g' | sed 's/^(HEAD detached at \(.*\))$$/\1-$(BUILD_VCS_NUMBER)/g')

REGISTRY?=docker.pkg.github.com/sergelogvinov/devops-containers
DOCKER_HOST?=
BUILDARG?=

#

help:
	@awk 'BEGIN {FS = ":.*?## "} /^[0-9a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)


build: ## Build base images
	docker build $(BUILDARG) --rm -t $(REGISTRY)/devops-containers:base-$(CODE_TAG) \
		-f Dockerfile --target=base .
	docker build $(BUILDARG) --rm -t $(REGISTRY)/devops-containers:kube-$(CODE_TAG) \
		-f Dockerfile --target=kube .


build-dev: ## Build develop environment
	docker build $(BUILDARG) --rm -t $(REGISTRY)/devops-containers:dev-$(CODE_TAG) \
		-f Dockerfile --target=dev .

push:
	docker push $(REGISTRY)/devops-containers:kube-$(CODE_TAG)
	docker push $(REGISTRY)/devops-containers:dev-$(CODE_TAG)
