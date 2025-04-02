#!/bin/bash

# Set AWS region
AWS_REGION=$(aws configure get region)
if [ -z "$AWS_REGION" ]; then
  AWS_REGION="eu-south-2"
fi

# Create ECR repository for the generic letter service
repo_name="letter-image-generator-letter-service"
echo "Creating repository for $repo_name..."
aws ecr create-repository \
  --repository-name "$repo_name" \
  --image-scanning-configuration scanOnPush=true \
  --region "$AWS_REGION" || echo "Repository $repo_name already exists or couldn't be created"

# Create ECR repository for the generic number service
repo_name="letter-image-generator-number-service"
echo "Creating repository for $repo_name..."
aws ecr create-repository \
  --repository-name "$repo_name" \
  --image-scanning-configuration scanOnPush=true \
  --region "$AWS_REGION" || echo "Repository $repo_name already exists or couldn't be created"

# Create ECR repository for special character service
repo_name="letter-image-generator-special-char-service"
echo "Creating repository for $repo_name..."
aws ecr create-repository \
  --repository-name "$repo_name" \
  --image-scanning-configuration scanOnPush=true \
  --region "$AWS_REGION" || echo "Repository $repo_name already exists or couldn't be created"

echo "ECR repository creation complete!"
