#!/bin/bash

# This script deploys the CI/CD pipeline CloudFormation stack

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Set default values
STACK_NAME="letter-image-generator-pipeline"
REPO_NAME="letter-image-generator"
BRANCH_NAME="main"
PROJECT_NAME="letter-image-generator"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --stack-name)
        STACK_NAME="$2"
        shift
        shift
        ;;
        --repo-name)
        REPO_NAME="$2"
        shift
        shift
        ;;
        --branch-name)
        BRANCH_NAME="$2"
        shift
        shift
        ;;
        --project-name)
        PROJECT_NAME="$2"
        shift
        shift
        ;;
        *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

echo "Deploying CloudFormation stack: $STACK_NAME"
echo "Repository name: $REPO_NAME"
echo "Branch name: $BRANCH_NAME"
echo "Project name: $PROJECT_NAME"

# Deploy the CloudFormation stack
aws cloudformation create-stack \
  --stack-name $STACK_NAME \
  --template-body file://$(dirname "$0")/../pipeline.yaml \
  --capabilities CAPABILITY_IAM \
  --parameters \
    ParameterKey=RepositoryName,ParameterValue=$REPO_NAME \
    ParameterKey=BranchName,ParameterValue=$BRANCH_NAME \
    ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME

echo "Stack creation initiated. You can monitor the progress in the AWS CloudFormation console."
echo "Once the stack is created, run the setup-codecommit.sh script to push your code to the repository."
