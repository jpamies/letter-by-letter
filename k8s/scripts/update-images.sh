#!/bin/bash

# Script to update ECR image references in the production kustomization file

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

# Path to the production kustomization file
KUSTOMIZATION_FILE="../overlays/prod/kustomization.yaml"

# Check if the file exists
if [ ! -f "$KUSTOMIZATION_FILE" ]; then
    echo "Error: Kustomization file not found at $KUSTOMIZATION_FILE"
    exit 1
fi

echo "Updating image references in $KUSTOMIZATION_FILE..."

# Create a temporary file
TMP_FILE=$(mktemp)

# Replace the placeholder account ID and region with actual values
sed "s/123456789012\.dkr\.ecr\.us-west-2\.amazonaws\.com/$AWS_ACCOUNT_ID\.dkr\.ecr\.$AWS_REGION\.amazonaws\.com/g" "$KUSTOMIZATION_FILE" > "$TMP_FILE"

# Replace the original file with the updated one
mv "$TMP_FILE" "$KUSTOMIZATION_FILE"

echo "Image references updated successfully!"
echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "AWS Region: $AWS_REGION"
