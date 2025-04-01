# Build Configuration for Letter-by-Letter Image Generator

This directory contains build specifications and scripts for the Letter-by-Letter Image Generator EKS AutoMode Demo.

## Components

- **buildspec.yml**: CodeBuild specification for building Docker images
- **scripts/**: Utility scripts for creating ECR repositories and CodeBuild projects

## Setup Instructions

### Prerequisites

- AWS CLI installed and configured
- Appropriate IAM permissions

### Creating ECR Repositories

To create ECR repositories for each service:

```bash
./scripts/create-ecr-repos.sh
```

This creates ECR repositories for each service (frontend, orchestrator, compositor) in your configured AWS region.

### Creating CodeBuild Projects

To create CodeBuild projects for each service:

```bash
./scripts/create-codebuild-projects.sh
```

This creates individual CodeBuild projects that can be used with your GitHub-based pipeline.

## Build Process

The `buildspec.yml` file defines the build process for each service:

1. **Pre-build**: Log in to Amazon ECR and prepare image tags
2. **Build**: Build Docker images for the service
3. **Post-build**: Push images to ECR and create image definition files

## Environment Variables

The following environment variables should be set in your CodeBuild projects:

- `ECR_REPOSITORY_URI`: The URI of the ECR repository for the service
- `SERVICE_DIR`: The directory containing the service code (e.g., "frontend", "orchestrator-service")

## Troubleshooting

If you encounter issues with the build process:

1. Check that IAM permissions are correctly configured
2. Verify that ECR repositories are accessible
3. Ensure environment variables are properly set in CodeBuild projects
