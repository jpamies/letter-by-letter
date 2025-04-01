# CI/CD Pipeline for Letter-by-Letter Image Generator

This directory contains CloudFormation templates and scripts to set up the CI/CD pipeline for the Letter-by-Letter Image Generator EKS AutoMode Demo.

## Components

- **ECR Repositories**: For storing Docker images of each service
- **CodeCommit Repository**: For source code version control
- **CodeBuild Projects**: For building Docker images
- **CodePipeline**: For orchestrating the CI/CD workflow

## Setup Instructions

### Prerequisites

- AWS CLI installed and configured
- Appropriate IAM permissions
- The AmazonECR-FullAccess policy should be created

### Option 1: Complete Pipeline Setup

Deploy the complete pipeline with a single command:

```bash
./scripts/deploy-pipeline.sh
```

This will:
1. Create ECR repositories for each service
2. Set up S3 buckets for artifacts
3. Configure CodeBuild projects
4. Create the CodePipeline

### Option 2: Step-by-Step Setup

If you prefer to set up components individually:

#### 1. Create CodeCommit Repository

```bash
./scripts/create-codecommit-repo.sh
```

This creates a CodeCommit repository in the eu-west-1 region.

#### 2. Create ECR Repositories

```bash
./scripts/create-ecr-repos.sh
```

This creates ECR repositories for each service (frontend, orchestrator, compositor) in the eu-south-2 region.

#### 3. Create CodeBuild Projects

```bash
./scripts/create-codebuild-projects.sh
```

This creates individual CodeBuild projects for each service.

## Pipeline Workflow

1. **Source Stage**: Code changes are detected in the CodeCommit repository
2. **Build Stage**: Docker images are built and pushed to ECR repositories
3. **Deploy Stage**: (To be implemented) Deploy to EKS cluster

## Project Structure

```
pipeline/
├── pipeline.yaml                # Main CloudFormation template
├── buildspec.yml               # Build specification for CodeBuild
├── README.md                   # This documentation
└── scripts/
    ├── create-codecommit-repo.sh    # Script to create CodeCommit repository
    ├── create-codebuild-projects.sh # Script to create CodeBuild projects
    ├── create-ecr-repos.sh          # Script to create ECR repositories
    └── deploy-pipeline.sh           # Main deployment script
```

## Troubleshooting

If you encounter issues with the pipeline deployment:

1. Check CloudFormation stack events for error details
2. Ensure IAM permissions are correctly configured
3. Verify that the CodeCommit repository exists in the specified region
4. Check that ECR repositories are accessible

## Notes

- The pipeline is configured to work across multiple AWS regions (CodeCommit in eu-west-1, build/deploy in eu-south-2)
- Each service has its own ECR repository with lifecycle policies to manage image retention
- The pipeline automatically triggers on code changes to the main branch
