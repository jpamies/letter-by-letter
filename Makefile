# Variables
PODMAN := podman
AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "123456789012")
AWS_REGION := $(shell aws configure get region 2>/dev/null || echo "us-west-2")
ECR_REGISTRY := $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
VERSION := $(shell cat VERSION)
PLATFORMS := linux/amd64,linux/arm64

# Local development targets
.PHONY: local build ps logs down

build:
	@echo "Building all services with podman..."
	$(PODMAN) compose -f podman-compose.yml build

local: build
	@echo "Starting all services with podman..."
	$(PODMAN) compose -f podman-compose.yml up -d

ps:
	@echo "Listing running services..."
	$(PODMAN) compose -f podman-compose.yml ps

logs:
	@echo "Showing logs from all services..."
	$(PODMAN) compose -f podman-compose.yml logs

down:
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
	@echo "Deployments restarted. Use 'kubectl get pods -n letter-image-generator' to monitor the rollout."

k8s-setup-pod-identity:
	@echo "Setting up EKS Pod Identity for ECR access..."
	cd k8s/scripts && ./setup-pod-identity.sh

# Build and push images to ECR
.PHONY: ecr-build-push ecr-build-push-multi-arch version-bump

ecr-build-push:
	@echo "Building and pushing images to ECR..."
	cd k8s/scripts && ./build-and-push-images.sh

# Multi-architecture build and push
ecr-build-push-multi-arch:
	@echo "Building and pushing multi-architecture images to ECR (version: $(VERSION))..."
	$(PODMAN) buildx create --name multi-arch-builder --use || true
	@echo "Building frontend..."
	cd frontend && $(PODMAN) buildx build --platform $(PLATFORMS) \
		-t $(ECR_REGISTRY)/frontend:$(VERSION) \
		-t $(ECR_REGISTRY)/frontend:latest --push .
	@echo "Building orchestrator service..."
	cd orchestrator-service && $(PODMAN) buildx build --platform $(PLATFORMS) \
		-t $(ECR_REGISTRY)/orchestrator:$(VERSION) \
		-t $(ECR_REGISTRY)/orchestrator:latest --push .
	@echo "Building image compositor service..."
	cd image-compositor-service && $(PODMAN) buildx build --platform $(PLATFORMS) \
		-t $(ECR_REGISTRY)/compositor:$(VERSION) \
		-t $(ECR_REGISTRY)/compositor:latest --push .
	@echo "Building letter services..."
	for service in letter-services/*; do \
		if [ -d "$$service" ]; then \
			service_name=$$(basename $$service); \
			echo "Building $$service_name..."; \
			cd $$service && $(PODMAN) buildx build --platform $(PLATFORMS) \
				-t $(ECR_REGISTRY)/$$service_name:$(VERSION) \
				-t $(ECR_REGISTRY)/$$service_name:latest --push . && cd ../..; \
		fi; \
	done
	@echo "Building number services..."
	for service in number-services/*; do \
		if [ -d "$$service" ]; then \
			service_name=$$(basename $$service); \
			echo "Building $$service_name..."; \
			cd $$service && $(PODMAN) buildx build --platform $(PLATFORMS) \
				-t $(ECR_REGISTRY)/$$service_name:$(VERSION) \
				-t $(ECR_REGISTRY)/$$service_name:latest --push . && cd ../..; \
		fi; \
	done
	@echo "Building special character service..."
	cd special-char-service && $(PODMAN) buildx build --platform $(PLATFORMS) \
		-t $(ECR_REGISTRY)/special-char:$(VERSION) \
		-t $(ECR_REGISTRY)/special-char:latest --push .
	@echo "Multi-architecture build and push complete for version $(VERSION)"

# Version management
version-bump:
	@if [ -z "$(NEW_VERSION)" ]; then \
		echo "Error: NEW_VERSION is required. Use 'make version-bump NEW_VERSION=x.y.z'"; \
		exit 1; \
	fi
	@echo "Bumping version from $(VERSION) to $(NEW_VERSION)"
	@echo "$(NEW_VERSION)" > VERSION
	@echo "Version updated to $(NEW_VERSION)"
	@echo "Don't forget to commit the change: git commit -am 'Bump version to $(NEW_VERSION)'"
