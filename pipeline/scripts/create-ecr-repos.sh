#!/bin/bash

# This script creates ECR repositories for the Letter-by-Letter Image Generator services

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Set default values
PROJECT_NAME="letter-image-generator"
ECR_REGION="eu-south-2"

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
        ECR_REGION="$2"
        shift
        shift
        ;;
        *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

echo "Creating ECR repositories for project: $PROJECT_NAME in region $ECR_REGION"

# Create ECR repositories for each service
for service in "frontend" "orchestrator" "compositor"; do
    repo_name="${PROJECT_NAME}-${service}"
    echo "Creating ECR repository: $repo_name"
    
    # Create the ECR repository
    aws ecr create-repository \
      --repository-name $repo_name \
      --image-scanning-configuration scanOnPush=true \
      --region $ECR_REGION
    
    # Add lifecycle policy
    aws ecr put-lifecycle-policy \
      --repository-name $repo_name \
      --lifecycle-policy-text '{"rules":[{"rulePriority":1,"description":"Keep only the last 10 images","selection":{"tagStatus":"any","countType":"imageCountMoreThan","countNumber":10},"action":{"type":"expire"}}]}' \
      --region $ECR_REGION
done

echo "ECR repositories created successfully."
