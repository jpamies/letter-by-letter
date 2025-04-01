#!/bin/bash

# Script to build and push images to ECR for the Letter-by-Letter Image Generator

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

# Project root directory (assuming this script is in k8s/scripts)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Services to build and push
SERVICES=(
    "frontend"
    "orchestrator-service"
    "image-compositor-service"
)

# Authenticate with ECR
echo "Authenticating with ECR..."
aws ecr get-login-password --region "$AWS_REGION" | podman login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# Build and push each service
for service in "${SERVICES[@]}"; do
    # Convert service name to repository name
    if [[ "$service" == "frontend" ]]; then
        REPO_NAME="letter-image-generator-frontend"
    elif [[ "$service" == "orchestrator-service" ]]; then
        REPO_NAME="letter-image-generator-orchestrator"
    elif [[ "$service" == "image-compositor-service" ]]; then
        REPO_NAME="letter-image-generator-compositor"
    else
        REPO_NAME="letter-image-generator-$service"
    fi
    
    echo "Building $service..."
    cd "$PROJECT_ROOT/$service" || { echo "Error: Directory $PROJECT_ROOT/$service not found"; continue; }
    
    # Build the image
    podman build -t "$REPO_NAME:latest" .
    
    # Tag the image for ECR
    podman tag "$REPO_NAME:latest" "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest"
    
    # Push to ECR
    echo "Pushing $REPO_NAME to ECR..."
    podman push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest"
    
    echo "$service built and pushed successfully!"
done

echo "All images have been built and pushed to ECR!"
