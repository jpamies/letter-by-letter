# Variables
PODMAN := podman
AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "123456789012")
AWS_REGION := $(shell aws configure get region 2>/dev/null || echo "us-west-2")
ECR_REGISTRY := $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

# Local development targets
.PHONY: local build ps logs down

build:
	@echo "Building all services with podman..."
	$(PODMAN) compose -f docker-compose.yml build

local: build
	@echo "Starting all services with podman..."
	$(PODMAN) compose -f docker-compose.yml up -d

ps:
	@echo "Listing running services..."
	$(PODMAN) compose -f docker-compose.yml ps

logs:
	@echo "Showing logs from all services..."
	$(PODMAN) compose -f docker-compose.yml logs

down:
	@echo "Stopping all services..."
	$(PODMAN) compose -f docker-compose.yml down

# Kubernetes deployment targets
.PHONY: k8s-local k8s-down k8s-prod k8s-restart k8s-setup-pod-identity

k8s-local:
	@echo "Deploying to local Kubernetes..."
	kubectl apply -k k8s/overlays/local

k8s-down:
	@echo "Removing Kubernetes deployment..."
	kubectl delete -k k8s/overlays/local

k8s-prod:
	@echo "Deploying to production EKS cluster..."
	kubectl apply -k k8s/overlays/prod

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
.PHONY: ecr-build-push

ecr-build-push:
	@echo "Building and pushing images to ECR..."
	cd k8s/scripts && ./build-and-push-images.sh
