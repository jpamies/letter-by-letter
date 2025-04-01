#!/bin/bash

# This script deletes the ECR stack to allow the full pipeline stack to be created

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Set default values
ECR_STACK_NAME="letter-image-generator-ecr"
PIPELINE_REGION="eu-south-2"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --stack-name)
        ECR_STACK_NAME="$2"
        shift
        shift
        ;;
        --region)
        PIPELINE_REGION="$2"
        shift
        shift
        ;;
        *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

echo "Deleting ECR stack: $ECR_STACK_NAME in region $PIPELINE_REGION"

# Delete the ECR stack
aws cloudformation delete-stack --stack-name $ECR_STACK_NAME --region $PIPELINE_REGION

echo "Waiting for stack deletion to complete..."
aws cloudformation wait stack-delete-complete --stack-name $ECR_STACK_NAME --region $PIPELINE_REGION

echo "ECR stack deletion complete. You can now deploy the full pipeline stack."
