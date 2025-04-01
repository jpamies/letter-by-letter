# Makefile for Letter-by-Letter Image Generator
# Uses podman instead of docker for local development

# Variables
PODMAN = podman
COMPOSE = $(PODMAN)-compose
COMPOSE_FILE = docker-compose.yml
SERVICES = frontend orchestrator-service image-compositor-service
K8S_DEV = k8s/overlays/dev
K8S_PROD = k8s/overlays/prod

# Default target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  local       - Build and run all services locally using podman"
	@echo "  build       - Build all service images"
	@echo "  up          - Start all services"
	@echo "  down        - Stop all services"
	@echo "  clean       - Remove all containers and images"
	@echo "  logs        - Show logs from all services"
	@echo "  ps          - Show running containers"
	@echo "  build-<service> - Build a specific service (e.g., build-frontend)"
	@echo "  test        - Run tests for all services"
	@echo "  k8s-local   - Deploy to local Kubernetes using podman"
	@echo "  k8s-down    - Remove local Kubernetes deployment"
	@echo "  k8s-dev     - Deploy to development Kubernetes cluster"
	@echo "  k8s-prod    - Deploy to production Kubernetes cluster"

# Build and run locally
.PHONY: local
local: build up

# Build all services
.PHONY: build
build:
	@echo "Building all services with podman..."
	$(COMPOSE) -f $(COMPOSE_FILE) build

# Start all services
.PHONY: up
up:
	@echo "Starting all services with podman..."
	$(COMPOSE) -f $(COMPOSE_FILE) up -d

# Stop all services
.PHONY: down
down:
	@echo "Stopping all services..."
	$(COMPOSE) -f $(COMPOSE_FILE) down

# Show logs
.PHONY: logs
logs:
	@echo "Showing logs from all services..."
	$(COMPOSE) -f $(COMPOSE_FILE) logs -f

# Show running containers
.PHONY: ps
ps:
	@echo "Showing running containers..."
	$(COMPOSE) -f $(COMPOSE_FILE) ps

# Clean up
.PHONY: clean
clean: down
	@echo "Removing all containers and images..."
	$(PODMAN) system prune -af

# Build individual services
.PHONY: build-frontend build-orchestrator build-compositor
build-frontend:
	@echo "Building frontend service..."
	$(COMPOSE) -f $(COMPOSE_FILE) build frontend

build-orchestrator:
	@echo "Building orchestrator service..."
	$(COMPOSE) -f $(COMPOSE_FILE) build orchestrator

build-compositor:
	@echo "Building image compositor service..."
	$(COMPOSE) -f $(COMPOSE_FILE) build compositor

# Run tests
.PHONY: test
test:
	@echo "Running tests for all services..."
	@for service in $(SERVICES); do \
		echo "Testing $$service..."; \
		cd $$service && npm test || echo "No tests found for $$service"; \
		cd ..; \
	done

# Create letter service
.PHONY: create-letter-service
create-letter-service:
	@read -p "Enter letter (A-Z): " letter; \
	mkdir -p letter-services/$$letter-service; \
	echo "Creating letter service for $$letter..."; \
	cp -r templates/letter-service/* letter-services/$$letter-service/ || echo "No template found, creating empty directory"

# Create number service
.PHONY: create-number-service
create-number-service:
	@read -p "Enter number (0-9): " number; \
	mkdir -p number-services/$$number-service; \
	echo "Creating number service for $$number..."; \
	cp -r templates/number-service/* number-services/$$number-service/ || echo "No template found, creating empty directory"

# Kubernetes targets
.PHONY: k8s-local k8s-down k8s-dev k8s-prod k8s-create-namespaces
k8s-create-namespaces:
	@echo "Creating Kubernetes namespaces..."
	kubectl apply -f $(K8S_DEV)/../base/namespaces.yaml

k8s-local:
	@echo "Deploying to local Kubernetes using podman..."
	$(PODMAN) kube play --network=podman $(K8S_DEV)

k8s-down:
	@echo "Removing local Kubernetes deployment..."
	$(PODMAN) kube down $(K8S_DEV)

k8s-dev:
	@echo "Deploying to development Kubernetes cluster..."
	kubectl apply -f $(K8S_DEV)/../base/namespaces.yaml
	kubectl apply -k $(K8S_DEV)

k8s-prod:
	@echo "Deploying to production Kubernetes cluster..."
	kubectl apply -f $(K8S_PROD)/../base/namespaces.yaml
	kubectl apply -k $(K8S_PROD)
