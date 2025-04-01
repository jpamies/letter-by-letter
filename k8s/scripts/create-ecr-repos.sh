#!/bin/bash

# Script to create ECR repositories for the Letter-by-Letter Image Generator

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    exit 1
fi

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ $? -ne 0 ]; then
    echo "Error: Failed to get AWS account ID. Make sure you're authenticated with AWS."
    exit 1
fi

# Get AWS region
AWS_REGION=$(aws configure get region)
if [ -z "$AWS_REGION" ]; then
    echo "Error: AWS region not found. Please configure AWS CLI with a default region."
    exit 1
fi

# List of repositories to create
REPOS=(
    "letter-image-generator-frontend"
    "letter-image-generator-orchestrator"
    "letter-image-generator-compositor"
)

echo "Creating ECR repositories in account $AWS_ACCOUNT_ID, region $AWS_REGION..."

# Create repositories if they don't exist
for repo in "${REPOS[@]}"; do
    if aws ecr describe-repositories --repository-names "$repo" --region "$AWS_REGION" &> /dev/null; then
        echo "Repository $repo already exists."
    else
        echo "Creating repository $repo..."
        aws ecr create-repository --repository-name "$repo" --region "$AWS_REGION"
    fi
done

# Get ECR login token and authenticate Docker/Podman
echo "Authenticating with ECR..."
aws ecr get-login-password --region "$AWS_REGION" | podman login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

echo "ECR setup complete!"
echo "To push images to ECR, use:"
echo "podman tag local-image:tag $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/repo-name:tag"
echo "podman push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/repo-name:tag"
