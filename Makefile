#

TAG ?= $(shell git rev-parse --short=7 HEAD)
BRANCH ?= $(shell git branch 2>/dev/null | sed -n '/^\*/s/^\* //p' | sed 's/^(HEAD detached at \(.*\))$$/\1/g')
BRANCH := $(shell echo $(BRANCH) | sed 's/\//-/g' | sed 's/\#//g')

REGISTRY?=ghcr.io/sergelogvinov/devops-containers
BUILDARG?=

ifneq ($(PLATFORM),)
BUILDARG += --platform=$(PLATFORM)
endif
ifeq ($(PUSH),true)
BUILDARG += --push=$(PUSH)
endif

#

help:
	@awk 'BEGIN {FS = ":.*?## "} /^[0-9a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)


build: ## Build base images
	docker buildx build $(BUILDARG) --rm -t $(REGISTRY)/devops-containers:base-$(BRANCH) \
		-f Dockerfile --target=base .
	docker buildx build $(BUILDARG) --rm -t $(REGISTRY)/devops-containers:kube-$(BRANCH) \
		-f Dockerfile --target=kube .
	docker buildx build $(BUILDARG) --rm -t $(REGISTRY)/devops-containers:aws-$(BRANCH) \
		-f Dockerfile --target=aws .

build-dev: ## Build develop environment
	docker buildx build $(BUILDARG) --rm -t $(REGISTRY)/devops-containers:dev-$(BRANCH) \
		-f Dockerfile --target=dev .
	docker buildx build $(BUILDARG) --rm -t $(REGISTRY)/devops-containers:pytest-$(BRANCH) \
		-f Dockerfile --target=pytest .
