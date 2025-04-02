# Variables
PODMAN := podman
AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "123456789012")
AWS_REGION := $(shell aws configure get region 2>/dev/null || echo "us-west-2")
ECR_REGISTRY := $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
VERSION := $(shell cat VERSION)
PLATFORMS := linux/amd64,linux/arm64

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
.PHONY: k8s-deploy k8s-down k8s-restart k8s-setup-pod-identity

k8s-deploy:
	@echo "Deploying to Kubernetes..."
	kubectl apply -f k8s/

k8s-down:
	@echo "Removing Kubernetes deployment..."
	kubectl delete -f k8s/

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
.PHONY: build ecr-build-push-multi-arch

build: version-patch-bump ecr-build-push-multi-arch
k8s-deploy:
# Multi-architecture build and push
ecr-build-push-multi-arch:
	@echo "Building and pushing multi-architecture images to ECR (version: $(VERSION))..."
	@echo "Logging in to ECR..."
	aws ecr get-login-password --region $(AWS_REGION) | $(PODMAN) login --username AWS --password-stdin $(ECR_REGISTRY)
	
	@echo "Building and pushing multi-architecture images..."
	
	# Frontend service
	@echo "Building frontend for amd64..."
	cd frontend && $(PODMAN) build --arch=amd64 -t $(ECR_REGISTRY)/letter-image-generator-frontend:$(VERSION)-amd64 .
	@echo "Building frontend for arm64..."
	cd frontend && $(PODMAN) build --arch=arm64 -t $(ECR_REGISTRY)/letter-image-generator-frontend:$(VERSION)-arm64 .
	$(PODMAN) push $(ECR_REGISTRY)/letter-image-generator-frontend:$(VERSION)-amd64
	$(PODMAN) push $(ECR_REGISTRY)/letter-image-generator-frontend:$(VERSION)-arm64
	$(PODMAN) manifest create $(ECR_REGISTRY)/letter-image-generator-frontend:$(VERSION) $(ECR_REGISTRY)/letter-image-generator-frontend:$(VERSION)-amd64 $(ECR_REGISTRY)/letter-image-generator-frontend:$(VERSION)-arm64
	$(PODMAN) manifest push $(ECR_REGISTRY)/letter-image-generator-frontend:$(VERSION)
	$(PODMAN) manifest rm $(ECR_REGISTRY)/letter-image-generator-frontend:latest 2>/dev/null || true
	$(PODMAN) manifest create $(ECR_REGISTRY)/letter-image-generator-frontend:latest $(ECR_REGISTRY)/letter-image-generator-frontend:$(VERSION)-amd64 $(ECR_REGISTRY)/letter-image-generator-frontend:$(VERSION)-arm64
	$(PODMAN) manifest push $(ECR_REGISTRY)/letter-image-generator-frontend:latest
	
	# Orchestrator service
	@echo "Building orchestrator service..."
	cd orchestrator-service && $(PODMAN) build --arch=amd64 -t $(ECR_REGISTRY)/letter-image-generator-orchestrator:$(VERSION)-amd64 .
	cd orchestrator-service && $(PODMAN) build --arch=arm64 -t $(ECR_REGISTRY)/letter-image-generator-orchestrator:$(VERSION)-arm64 .
	$(PODMAN) push $(ECR_REGISTRY)/letter-image-generator-orchestrator:$(VERSION)-amd64
	$(PODMAN) push $(ECR_REGISTRY)/letter-image-generator-orchestrator:$(VERSION)-arm64
	$(PODMAN) manifest create $(ECR_REGISTRY)/letter-image-generator-orchestrator:$(VERSION) $(ECR_REGISTRY)/letter-image-generator-orchestrator:$(VERSION)-amd64 $(ECR_REGISTRY)/letter-image-generator-orchestrator:$(VERSION)-arm64
	$(PODMAN) manifest push $(ECR_REGISTRY)/letter-image-generator-orchestrator:$(VERSION)
	$(PODMAN) manifest rm $(ECR_REGISTRY)/letter-image-generator-orchestrator:latest 2>/dev/null || true
	$(PODMAN) manifest create $(ECR_REGISTRY)/letter-image-generator-orchestrator:latest $(ECR_REGISTRY)/letter-image-generator-orchestrator:$(VERSION)-amd64 $(ECR_REGISTRY)/letter-image-generator-orchestrator:$(VERSION)-arm64
	$(PODMAN) manifest push $(ECR_REGISTRY)/letter-image-generator-orchestrator:latest
	
	# Image compositor service
	@echo "Building image compositor service..."
	cd image-compositor-service && $(PODMAN) build --arch=amd64 -t $(ECR_REGISTRY)/letter-image-generator-compositor:$(VERSION)-amd64 .
	cd image-compositor-service && $(PODMAN) build --arch=arm64 -t $(ECR_REGISTRY)/letter-image-generator-compositor:$(VERSION)-arm64 .
	$(PODMAN) push $(ECR_REGISTRY)/letter-image-generator-compositor:$(VERSION)-amd64
	$(PODMAN) push $(ECR_REGISTRY)/letter-image-generator-compositor:$(VERSION)-arm64
	$(PODMAN) manifest create $(ECR_REGISTRY)/letter-image-generator-compositor:$(VERSION) $(ECR_REGISTRY)/letter-image-generator-compositor:$(VERSION)-amd64 $(ECR_REGISTRY)/letter-image-generator-compositor:$(VERSION)-arm64
	$(PODMAN) manifest push $(ECR_REGISTRY)/letter-image-generator-compositor:$(VERSION)
	$(PODMAN) manifest rm $(ECR_REGISTRY)/letter-image-generator-compositor:latest 2>/dev/null || true
	$(PODMAN) manifest create $(ECR_REGISTRY)/letter-image-generator-compositor:latest $(ECR_REGISTRY)/letter-image-generator-compositor:$(VERSION)-amd64 $(ECR_REGISTRY)/letter-image-generator-compositor:$(VERSION)-arm64
	$(PODMAN) manifest push $(ECR_REGISTRY)/letter-image-generator-compositor:latest
	
	# Generic letter service
	@echo "Building letter service..."
	cd letter-service && $(PODMAN) build --arch=amd64 -t $(ECR_REGISTRY)/letter-image-generator-letter-service:$(VERSION)-amd64 .
	cd letter-service && $(PODMAN) build --arch=arm64 -t $(ECR_REGISTRY)/letter-image-generator-letter-service:$(VERSION)-arm64 .
	$(PODMAN) push $(ECR_REGISTRY)/letter-image-generator-letter-service:$(VERSION)-amd64
	$(PODMAN) push $(ECR_REGISTRY)/letter-image-generator-letter-service:$(VERSION)-arm64
	$(PODMAN) manifest create $(ECR_REGISTRY)/letter-image-generator-letter-service:$(VERSION) $(ECR_REGISTRY)/letter-image-generator-letter-service:$(VERSION)-amd64 $(ECR_REGISTRY)/letter-image-generator-letter-service:$(VERSION)-arm64
	$(PODMAN) manifest push $(ECR_REGISTRY)/letter-image-generator-letter-service:$(VERSION)
	$(PODMAN) manifest rm $(ECR_REGISTRY)/letter-image-generator-letter-service:latest 2>/dev/null || true
	$(PODMAN) manifest create $(ECR_REGISTRY)/letter-image-generator-letter-service:latest $(ECR_REGISTRY)/letter-image-generator-letter-service:$(VERSION)-amd64 $(ECR_REGISTRY)/letter-image-generator-letter-service:$(VERSION)-arm64
	$(PODMAN) manifest push $(ECR_REGISTRY)/letter-image-generator-letter-service:latest
	
	# Generic number service
	@echo "Building number service..."
	cd number-service && $(PODMAN) build --arch=amd64 -t $(ECR_REGISTRY)/letter-image-generator-number-service:$(VERSION)-amd64 .
	cd number-service && $(PODMAN) build --arch=arm64 -t $(ECR_REGISTRY)/letter-image-generator-number-service:$(VERSION)-arm64 .
	$(PODMAN) push $(ECR_REGISTRY)/letter-image-generator-number-service:$(VERSION)-amd64
	$(PODMAN) push $(ECR_REGISTRY)/letter-image-generator-number-service:$(VERSION)-arm64
	$(PODMAN) manifest create $(ECR_REGISTRY)/letter-image-generator-number-service:$(VERSION) $(ECR_REGISTRY)/letter-image-generator-number-service:$(VERSION)-amd64 $(ECR_REGISTRY)/letter-image-generator-number-service:$(VERSION)-arm64
	$(PODMAN) manifest push $(ECR_REGISTRY)/letter-image-generator-number-service:$(VERSION)
	$(PODMAN) manifest rm $(ECR_REGISTRY)/letter-image-generator-number-service:latest 2>/dev/null || true
	$(PODMAN) manifest create $(ECR_REGISTRY)/letter-image-generator-number-service:latest $(ECR_REGISTRY)/letter-image-generator-number-service:$(VERSION)-amd64 $(ECR_REGISTRY)/letter-image-generator-number-service:$(VERSION)-arm64
	$(PODMAN) manifest push $(ECR_REGISTRY)/letter-image-generator-number-service:latest
	
	# Special character service
	@echo "Building special character service..."
	cd special-char-service && $(PODMAN) build --arch=amd64 -t $(ECR_REGISTRY)/letter-image-generator-special-char-service:$(VERSION)-amd64 .
	cd special-char-service && $(PODMAN) build --arch=arm64 -t $(ECR_REGISTRY)/letter-image-generator-special-char-service:$(VERSION)-arm64 .
	$(PODMAN) push $(ECR_REGISTRY)/letter-image-generator-special-char-service:$(VERSION)-amd64
	$(PODMAN) push $(ECR_REGISTRY)/letter-image-generator-special-char-service:$(VERSION)-arm64
	$(PODMAN) manifest create $(ECR_REGISTRY)/letter-image-generator-special-char-service:$(VERSION) $(ECR_REGISTRY)/letter-image-generator-special-char-service:$(VERSION)-amd64 $(ECR_REGISTRY)/letter-image-generator-special-char-service:$(VERSION)-arm64
	$(PODMAN) manifest push $(ECR_REGISTRY)/letter-image-generator-special-char-service:$(VERSION)
	$(PODMAN) manifest rm $(ECR_REGISTRY)/letter-image-generator-special-char-service:latest 2>/dev/null || true
	$(PODMAN) manifest create $(ECR_REGISTRY)/letter-image-generator-special-char-service:latest $(ECR_REGISTRY)/letter-image-generator-special-char-service:$(VERSION)-amd64 $(ECR_REGISTRY)/letter-image-generator-special-char-service:$(VERSION)-arm64
	$(PODMAN) manifest push $(ECR_REGISTRY)/letter-image-generator-special-char-service:latest
	
	@echo "Multi-architecture build and push complete for version $(VERSION)"

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

clean: down
	@echo "Cleaning up resources..."
	$(PODMAN) system prune -f

clean-images:
	@echo "Removing all local images..."
	$(PODMAN) container rm -f $$($(PODMAN) container ls -aq) 2>/dev/null || true
	$(PODMAN) images -a | grep -v "REPOSITORY" | awk '{print $$3}' | xargs -r $(PODMAN) rmi -f
	@echo "All local images have been removed."
