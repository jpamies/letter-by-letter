# Kubernetes Deployment for Letter-by-Letter Image Generator

This directory contains Kubernetes manifests for deploying the Letter-by-Letter Image Generator application to Kubernetes clusters, including Amazon EKS with AutoMode.

## Directory Structure

- `base/`: Base Kubernetes manifests common to all environments
- `overlays/`: Environment-specific configurations
  - `dev/`: Development environment configuration
  - `prod/`: Production environment configuration with EKS AutoMode settings

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

1. Set environment variables:
```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=$(aws configure get region)
```

2. Apply the Kubernetes manifests:
```bash
# For development environment
kubectl apply -k k8s/overlays/dev/

# For production environment
kubectl apply -k k8s/overlays/prod/
```

3. To delete the deployment:
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

## Local vs. Kubernetes Deployment

- **Local Development**: Use `make local` for a simple Docker Compose-based setup
- **Local Kubernetes**: Use `podman kube play` for testing Kubernetes configurations locally
- **EKS Deployment**: Use `kubectl apply -k` for deploying to Amazon EKS

## Adding New Services

When adding new letter or number services:

1. Create a new deployment and service manifest in the `base/` directory
2. Add the new files to the `kustomization.yaml` in the `base/` directory
3. Update the overlays as needed for environment-specific configurations
