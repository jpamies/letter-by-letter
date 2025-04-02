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
	kubectl rollout restart deployment/letter-service -n letter-image-generator
	kubectl rollout restart deployment/number-service -n letter-image-generator
	kubectl rollout restart deployment/special-char-service -n letter-image-generator
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
	$(PODMAN) manifest create $(ECR_REGISTRY)/letter-image-generator-special-char-service:latest $(ECR_REGISTRY)/letter-image-generator-special-char-service:$(VERSION)-amd64 $(ECR_REGISTRY)/letter-image-generator-special-char-service:$(VERSION)-arm64
	$(PODMAN) manifest push $(ECR_REGISTRY)/letter-image-generator-special-char-service:latest
	
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

# Deployment targets
.PHONY: deploy deploy-eks

deploy: ecr-build-push-multi-arch k8s-deploy k8s-restart
	@echo "Deployment complete. Application is now being deployed to EKS."
	@echo "To check the status, run: kubectl get pods -n letter-image-generator"
	@echo "To get the application URL, run: kubectl get ingress -n letter-image-generator"

deploy-eks: ecr-build-push-multi-arch k8s-setup-pod-identity k8s-deploy k8s-restart
	@echo "Full EKS deployment complete."
	@echo "To check the status, run: kubectl get pods -n letter-image-generator"
	@echo "To get the application URL, run: kubectl get ingress -n letter-image-generator"

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
