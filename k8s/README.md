# Kubernetes Deployment for Letter-by-Letter Image Generator

This directory contains Kubernetes manifests for deploying the Letter-by-Letter Image Generator application to Kubernetes clusters, including Amazon EKS with AutoMode.

## Directory Structure

- `base/`: Base Kubernetes manifests common to all environments
  - `namespaces.yaml`: Defines the namespace for the application
  - `*-deployment.yaml`: Deployment configurations for each service
  - `*-service.yaml`: Service configurations for each service
- `overlays/`: Environment-specific configurations
  - `dev/`: Development environment configuration
  - `prod/`: Production environment configuration with EKS AutoMode settings
- `scripts/`: Helper scripts for deployment
  - `update-images.sh`: Script to update ECR image references with actual AWS account and region

## Deployment Instructions

### Local Development with Podman

For local development with Podman Kubernetes, you can use:

```bash
# Create a local Kubernetes cluster with Podman
podman kube play --network=podman k8s/overlays/dev/

# To delete the local deployment
podman kube down k8s/overlays/dev/
```

### Deploying to EKS

1. Set environment variables and update image references:
```bash
# This will be done automatically when running make k8s-prod
make k8s-update-images
```

2. Create the required namespace:
```bash
kubectl apply -f k8s/base/namespaces.yaml
```

3. Apply the Kubernetes manifests:
```bash
# For development environment
make k8s-dev

# For production environment
make k8s-prod
```

4. To delete the deployment:
```bash
# For development environment
kubectl delete -k k8s/overlays/dev/

# For production environment
kubectl delete -k k8s/overlays/prod/
```

## EKS AutoMode Configuration

The production overlay includes configurations optimized for EKS AutoMode:

- Horizontal Pod Autoscalers (HPAs) for all services
- Resource requests and limits for efficient pod scheduling
- Multiple replicas for high availability

## Environment Strategy

Both development and production environments use the same namespace name (`letter-image-generator`) but are deployed to different clusters. Environment-specific configurations are managed through:

- Different image repositories (local for dev, ECR for prod)
- Different replica counts and scaling policies
- Environment labels that distinguish resources

## Adding New Services

When adding new letter or number services:

1. Create a new deployment and service manifest in the `base/` directory
2. Add the new files to the `kustomization.yaml` in the `base/` directory
3. Update the overlays as needed for environment-specific configurations
4. Update the `update-images.sh` script if the new service requires ECR images
