#!/bin/bash

# This script creates ECR repositories for each service

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Set default values
PROJECT_NAME="letter-image-generator"
REGION="eu-south-2"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --project-name)
        PROJECT_NAME="$2"
        shift
        shift
        ;;
        --region)
        REGION="$2"
        shift
        shift
        ;;
        *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

echo "Creating ECR repositories for project: $PROJECT_NAME in region: $REGION"

# Create ECR repositories for each service
services=("frontend" "orchestrator" "compositor")

for service in "${services[@]}"; do
    repo_name="${PROJECT_NAME}-${service}"
    echo "Creating ECR repository: $repo_name"
    
    aws ecr create-repository \
        --repository-name "$repo_name" \
        --image-scanning-configuration scanOnPush=true \
        --region "$REGION" || echo "Repository $repo_name already exists or couldn't be created"
    
    # Add lifecycle policy to keep only the last 10 images
    aws ecr put-lifecycle-policy \
        --repository-name "$repo_name" \
        --lifecycle-policy-text '{"rules":[{"rulePriority":1,"description":"Keep only the last 10 images","selection":{"tagStatus":"any","countType":"imageCountMoreThan","countNumber":10},"action":{"type":"expire"}}]}' \
        --region "$REGION" || echo "Failed to set lifecycle policy for $repo_name"
done

echo "ECR repositories created successfully."
