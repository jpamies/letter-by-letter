#!/bin/bash

# This script deletes ECR repositories for each service

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

echo "Deleting ECR repositories for project: $PROJECT_NAME in region: $REGION"

# Delete ECR repositories for each service
services=("frontend" "orchestrator" "compositor")

for service in "${services[@]}"; do
    repo_name="${PROJECT_NAME}-${service}"
    echo "Deleting ECR repository: $repo_name"
    
    aws ecr delete-repository \
        --repository-name "$repo_name" \
        --force \
        --region "$REGION" || echo "Repository $repo_name doesn't exist or couldn't be deleted"
done

echo "ECR repositories deleted successfully."
