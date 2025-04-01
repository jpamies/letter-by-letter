#!/bin/bash

# This script creates a CodeCommit repository in the specified region

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Set default values
REPO_NAME="letter-image-generator"
CODECOMMIT_REGION="eu-west-1"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --repo-name)
        REPO_NAME="$2"
        shift
        shift
        ;;
        --region)
        CODECOMMIT_REGION="$2"
        shift
        shift
        ;;
        *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

echo "Creating CodeCommit repository: $REPO_NAME in region $CODECOMMIT_REGION"

# Create the CodeCommit repository
aws codecommit create-repository \
  --repository-name $REPO_NAME \
  --repository-description "Letter-by-Letter Image Generator for EKS AutoMode Demo" \
  --region $CODECOMMIT_REGION

echo "CodeCommit repository created successfully."
echo "Clone URL HTTPS: https://git-codecommit.$CODECOMMIT_REGION.amazonaws.com/v1/repos/$REPO_NAME"
