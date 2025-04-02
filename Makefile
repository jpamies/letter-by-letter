# Variables
PODMAN := podman
AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "123456789012")
AWS_REGION := $(shell aws configure get region 2>/dev/null || echo "us-west-2")
ECR_REGISTRY := $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
VERSION := $(shell cat VERSION)
PLATFORM := linux/arm64/v8

# Local development targets
.PHONY: local local-build local-ps local-logs local-down

local-build:
	@echo "Building all services with podman..."
	$(PODMAN) compose -f podman-compose.yml build

local: local-build
	@echo "Starting all services with podman..."
	$(PODMAN) compose -f podman-compose.yml up -d

local-ps:
	@echo "Listing running services..."
	$(PODMAN) compose -f podman-compose.yml ps

local-logs:
	@echo "Showing logs from all services..."
	$(PODMAN) compose -f podman-compose.yml logs

local-down:
	@echo "Stopping all services..."
	$(PODMAN) compose -f podman-compose.yml down

# Kubernetes deployment targets
.PHONY: k8s-deploy k8s-down k8s-restart k8s-setup-pod-identity k8s-update-version

k8s-deploy:
	@echo "Deploying to Kubernetes with version $(VERSION)..."
	cd k8s && \
	sed -i.bak "s/newTag: .*/newTag: $(VERSION)/g" kustomization.yaml && \
	kubectl apply -k . && \
	rm kustomization.yaml.bak

k8s-update-version:
	@echo "Updating Kubernetes deployment to version $(VERSION)..."
	cd k8s && \
	sed -i.bak "s/newTag: .*/newTag: $(VERSION)/g" kustomization.yaml && \
	kubectl apply -k . && \
	rm kustomization.yaml.bak

k8s-down:
	@echo "Removing Kubernetes deployment..."
	kubectl delete namespace letter-image-generator

k8s-restart:
	@echo "Restarting deployments to pick up new images..."
	kubectl rollout restart deployment/frontend -n letter-image-generator
	kubectl rollout restart deployment/orchestrator -n letter-image-generator
	kubectl rollout restart deployment/compositor -n letter-image-generator
	kubectl rollout restart deployment/letter-service -n letter-image-generator
	kubectl rollout restart deployment/number-service -n letter-image-generator
	kubectl rollout restart deployment/special-char-service -n letter-image-generator
	@echo "Deployments restarted. Use 'kubectl get pods -n letter-image-generator' to monitor the rollout."

k8s-setup-pod-identity:
	@echo "Setting up EKS Pod Identity for ECR access..."
	cd k8s/scripts && ./setup-pod-identity.sh

# Build targets
.PHONY: build ecr-build-push

build: version-patch-bump ecr-build-push

# Build and deploy in one step
.PHONY: build-deploy
build-deploy: build k8s-update-version

# Helper function to build and push a service
# $(1) = service name (e.g., frontend)
# $(2) = directory name (e.g., frontend)
define build-push-service
	@echo "Building $(1) for arm64..."
	cd $(2) && $(PODMAN) build --platform=$(PLATFORM) -t $(ECR_REGISTRY)/letter-image-generator-$(1):$(VERSION) .
	$(PODMAN) push $(ECR_REGISTRY)/letter-image-generator-$(1):$(VERSION)
	$(PODMAN) tag $(ECR_REGISTRY)/letter-image-generator-$(1):$(VERSION) $(ECR_REGISTRY)/letter-image-generator-$(1):latest
	$(PODMAN) push $(ECR_REGISTRY)/letter-image-generator-$(1):latest
endef

# ARM64-only build and push
ecr-build-push:
	@echo "Building and pushing ARM64 images to ECR (version: $(VERSION))..."
	@echo "Logging in to ECR..."
	aws ecr get-login-password --region $(AWS_REGION) | $(PODMAN) login --username AWS --password-stdin $(ECR_REGISTRY)
	
	@echo "Building and pushing ARM64 images..."
	
	# Build and push all services using the helper function
	$(call build-push-service,frontend,frontend)
	$(call build-push-service,orchestrator,orchestrator-service)
	$(call build-push-service,compositor,image-compositor-service)
	$(call build-push-service,letter-service,letter-service)
	$(call build-push-service,number-service,number-service)
	$(call build-push-service,special-char-service,special-char-service)
	
	@echo "ARM64 build and push complete for version $(VERSION)"

# Auto version increment
.PHONY: version-patch-bump

version-patch-bump:
	@echo "Incrementing patch version..."
	@CURRENT_VERSION=$$(cat VERSION); \
	MAJOR=$$(echo $$CURRENT_VERSION | cut -d. -f1); \
	MINOR=$$(echo $$CURRENT_VERSION | cut -d. -f2); \
	PATCH=$$(echo $$CURRENT_VERSION | cut -d. -f3); \
	NEW_PATCH=$$((PATCH + 1)); \
	NEW_VERSION="$$MAJOR.$$MINOR.$$NEW_PATCH"; \
	echo "$$NEW_VERSION" > VERSION; \
	echo "Version updated from $$CURRENT_VERSION to $$NEW_VERSION"; \
	git add VERSION; \
	git commit -m "Bump version to $$NEW_VERSION for deployment" || true

# Clean up targets
.PHONY: clean clean-images

clean: local-down
	@echo "Cleaning up resources..."
	$(PODMAN) system prune -f

clean-images:
	@echo "Removing all local images..."
	$(PODMAN) container rm -f $$($(PODMAN) container ls -aq) 2>/dev/null || true
	$(PODMAN) images -a | grep -v "REPOSITORY" | awk '{print $$3}' | xargs -r $(PODMAN) rmi -f
	@echo "All local images have been removed."
