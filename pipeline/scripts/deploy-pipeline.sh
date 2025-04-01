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
CODECOMMIT_REGION="eu-west-1"
PIPELINE_REGION="eu-south-2"

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
        --codecommit-region)
        CODECOMMIT_REGION="$2"
        shift
        shift
        ;;
        --pipeline-region)
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

echo "Deploying CloudFormation stack: $STACK_NAME"
echo "Repository name: $REPO_NAME"
echo "Branch name: $BRANCH_NAME"
echo "Project name: $PROJECT_NAME"
echo "CodeCommit region: $CODECOMMIT_REGION"
echo "Pipeline region: $PIPELINE_REGION"

# First, delete the failed stack if it exists
echo "Checking if stack exists and needs to be deleted..."
if aws cloudformation describe-stacks --stack-name $STACK_NAME --region $PIPELINE_REGION &> /dev/null; then
    echo "Deleting existing stack..."
    aws cloudformation delete-stack --stack-name $STACK_NAME --region $PIPELINE_REGION
    echo "Waiting for stack deletion to complete..."
    aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME --region $PIPELINE_REGION
fi

# Deploy the CloudFormation stack for the pipeline resources
echo "Deploying pipeline resources in $PIPELINE_REGION..."
aws cloudformation create-stack \
  --stack-name $STACK_NAME \
  --template-body file://$(dirname "$0")/../pipeline.yaml \
  --capabilities CAPABILITY_IAM \
  --parameters \
    ParameterKey=RepositoryName,ParameterValue=$REPO_NAME \
    ParameterKey=BranchName,ParameterValue=$BRANCH_NAME \
    ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME \
    ParameterKey=CodeCommitRegion,ParameterValue=$CODECOMMIT_REGION \
  --region $PIPELINE_REGION

echo "Stack creation initiated. You can monitor the progress in the AWS CloudFormation console."
echo "Once the stack is created, the pipeline will automatically start when code is pushed to the repository."
