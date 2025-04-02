# Kubernetes Deployment for Letter-by-Letter Image Generator

This directory contains Kubernetes manifests for deploying the Letter-by-Letter Image Generator application to Amazon EKS with AutoMode.

## Deployment Structure

The application is deployed using Kustomize, which allows for version-specific deployments:

- `kustomization.yaml`: Main configuration file that references all resources and handles image versioning
- Individual resource files for deployments, services, HPAs, etc.

## Deployment Instructions

### Prerequisites

1. An Amazon EKS cluster with AutoMode enabled
2. `kubectl` configured to access your EKS cluster
3. ECR repositories for all services
4. AWS CLI configured with appropriate permissions

### Deploying the Application

To deploy the application with a specific version:

```bash
# From the project root directory
make k8s-deploy
```

This will:
1. Use Kustomize to generate the complete manifest
2. Replace the `latest` tag with the current version from the VERSION file
3. Apply the manifest to your Kubernetes cluster

### Updating the Application

After building new versions of the services:

```bash
# Build new versions and push to ECR
make build

# Update the Kubernetes deployment with the new version
make k8s-update-version
```

Alternatively, use the combined command:

```bash
make build-deploy
```

### Removing the Application

To remove the entire application from your cluster:

```bash
make k8s-down
```

## Monitoring

After deployment, you can monitor the application:

```bash
# Check pod status
kubectl get pods -n letter-image-generator

# Check services
kubectl get svc -n letter-image-generator

# Check horizontal pod autoscalers
kubectl get hpa -n letter-image-generator
```

## EKS AutoMode Features

This deployment takes advantage of EKS AutoMode features:

- **Automatic Scaling**: HPAs are configured for all services
- **Resource Optimization**: Appropriate resource requests and limits are set
- **Pod Density**: Services are distributed efficiently across the cluster
- **Cost Efficiency**: Idle services scale to zero when not in use

## Troubleshooting

If you encounter issues:

1. Check pod status and logs:
   ```bash
   kubectl get pods -n letter-image-generator
   kubectl logs -f <pod-name> -n letter-image-generator
   ```

2. Verify service connectivity:
   ```bash
   kubectl exec -it <pod-name> -n letter-image-generator -- curl <service-name>:3000/health
   ```

3. Check HPA status:
   ```bash
   kubectl describe hpa <hpa-name> -n letter-image-generator
   ```
