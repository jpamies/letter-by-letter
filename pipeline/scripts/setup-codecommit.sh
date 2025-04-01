#!/bin/bash

# This script helps set up the AWS CodeCommit repository and push the initial code

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Get the stack outputs
echo "Getting CodeCommit repository URL from CloudFormation stack..."
REPO_URL=$(aws cloudformation describe-stacks \
  --stack-name letter-image-generator-pipeline \
  --query "Stacks[0].Outputs[?OutputKey=='CodeCommitRepositoryUrl'].OutputValue" \
  --output text)

if [ -z "$REPO_URL" ]; then
    echo "Failed to get repository URL. Make sure the CloudFormation stack is deployed."
    exit 1
fi

echo "CodeCommit repository URL: $REPO_URL"

# Configure Git credentials helper for CodeCommit
echo "Configuring Git credentials helper for CodeCommit..."
git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true

# Add the CodeCommit repository as a remote
echo "Adding CodeCommit repository as a remote..."
git remote add codecommit $REPO_URL

# Push the code to CodeCommit
echo "Pushing code to CodeCommit..."
git push codecommit main

echo "Setup complete! Your code has been pushed to CodeCommit and the pipeline should start automatically."
