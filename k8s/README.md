# Kubernetes Deployment for Letter-by-Letter Image Generator

This directory contains Kubernetes manifests for deploying the Letter-by-Letter Image Generator application to Kubernetes clusters, including Amazon EKS with AutoMode.

## Directory Structure

- `base/`: Base Kubernetes manifests common to all environments
  - `namespaces.yaml`: Defines the namespace for the application
  - `service-account.yaml`: Defines the service account for ECR access
  - `*-deployment.yaml`: Deployment configurations for each service
  - `*-service.yaml`: Service configurations for each service
- `overlays/`: Environment-specific configurations
  - `dev/`: Development environment configuration
  - `prod/`: Production environment configuration with EKS AutoMode settings
- `scripts/`: Helper scripts for deployment
  - `update-images.sh`: Script to update ECR image references with actual AWS account and region
  - `create-ecr-repos.sh`: Script to create required ECR repositories
  - `build-and-push-images.sh`: Script to build and push images to ECR
  - `setup-pod-identity.sh`: Script to set up EKS Pod Identity for ECR access

## Deployment Instructions

### Local Development with Podman

For local development with Podman Kubernetes, you can use:

```bash
# Create a local Kubernetes cluster with Podman
make k8s-local

# To delete the local deployment
make k8s-down
```

### Deploying to EKS Development Environment

```bash
# Deploy to development environment
make k8s-dev
```

### Deploying to EKS Production Environment

For production deployment, you need to:

1. Create ECR repositories, build and push images, update image references, and set up Pod Identity:
```bash
# This will prepare everything for production deployment
make k8s-prod-prepare
```

2. Deploy to the production environment:
```bash
# This will deploy to production (includes preparation steps)
make k8s-prod
```

You can also run individual preparation steps:
```bash
# Create ECR repositories
make k8s-create-ecr

# Build and push images to ECR
make k8s-build-push

# Update image references in kustomization files
make k8s-update-images

# Set up EKS Pod Identity for ECR access
make k8s-setup-pod-identity
```

### Cleaning Up Deployments

To delete the deployment:
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
- EKS Pod Identity for secure ECR access

## Environment Strategy

Both development and production environments use the same namespace name (`letter-image-generator`) but are deployed to different clusters. Environment-specific configurations are managed through:

- Different image repositories (local for dev, ECR for prod)
- Different replica counts and scaling policies
- Environment labels that distinguish resources

## Troubleshooting

If you encounter image pull errors:
1. Ensure your EKS Pod Identity is set up correctly: `make k8s-setup-pod-identity`
2. Verify the ECR repositories exist: `aws ecr describe-repositories`
3. Check that images have been pushed: `aws ecr list-images --repository-name <repo-name>`
4. Verify the Pod Identity Association: `aws eks list-pod-identity-associations --cluster-name <cluster-name>`

## Adding New Services

When adding new letter or number services:

1. Create a new deployment and service manifest in the `base/` directory
2. Add the new files to the `kustomization.yaml` in the `base/` directory
3. Update the overlays as needed for environment-specific configurations
4. Add the new service to the `create-ecr-repos.sh` and `build-and-push-images.sh` scripts
5. Ensure the deployment uses the `ecr-pull-sa` service account
