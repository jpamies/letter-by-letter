#!/bin/bash

# This script creates CodeBuild projects for each service

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Set default values
PROJECT_NAME="letter-image-generator"
REGION="eu-south-2"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

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
        --account-id)
        ACCOUNT_ID="$2"
        shift
        shift
        ;;
        *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

echo "Creating CodeBuild projects for: $PROJECT_NAME in region: $REGION"

# Create service role for CodeBuild if it doesn't exist
ROLE_NAME="${PROJECT_NAME}-codebuild-role"
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

# Check if role exists
if ! aws iam get-role --role-name "$ROLE_NAME" &> /dev/null; then
    echo "Creating IAM role: $ROLE_NAME"
    
    # Create trust policy document
    cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    # Create role
    aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document file://trust-policy.json

    # Attach policies
    aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "arn:aws:iam::aws:policy/AmazonECR-FullAccess"
    aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
    
    # Create custom policy for CloudWatch Logs
    cat > logs-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF

    aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name "CloudWatchLogsAccess" --policy-document file://logs-policy.json
    
    # Clean up temporary files
    rm trust-policy.json logs-policy.json
    
    echo "IAM role created: $ROLE_NAME"
else
    echo "Using existing IAM role: $ROLE_NAME"
fi

# Create CodeBuild projects for each service
services=("frontend" "orchestrator" "compositor")
service_dirs=("frontend" "orchestrator-service" "image-compositor-service")

for i in "${!services[@]}"; do
    service="${services[$i]}"
    service_dir="${service_dirs[$i]}"
    project_name="${PROJECT_NAME}-${service}-build"
    repo_name="${PROJECT_NAME}-${service}"
    repo_uri="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${repo_name}"
    
    echo "Creating CodeBuild project: $project_name"
    
    # Create project definition
    cat > project-def.json << EOF
{
  "name": "${project_name}",
  "description": "Build project for the ${service} service",
  "source": {
    "type": "GITHUB",
    "location": "https://github.com/yourusername/${PROJECT_NAME}.git",
    "gitCloneDepth": 1,
    "buildspec": "pipeline/buildspec.yml"
  },
  "artifacts": {
    "type": "NO_ARTIFACTS"
  },
  "environment": {
    "type": "LINUX_CONTAINER",
    "image": "aws/codebuild/amazonlinux2-x86_64-standard:3.0",
    "computeType": "BUILD_GENERAL1_SMALL",
    "privilegedMode": true,
    "environmentVariables": [
      {
        "name": "ECR_REPOSITORY_URI",
        "value": "${repo_uri}"
      },
      {
        "name": "SERVICE_DIR",
        "value": "${service_dir}"
      }
    ]
  },
  "serviceRole": "${ROLE_ARN}"
}
EOF

    # Create or update the project
    if aws codebuild batch-get-projects --names "$project_name" --query "projects[0].name" --output text 2>/dev/null | grep -q "$project_name"; then
        echo "Updating existing CodeBuild project: $project_name"
        aws codebuild update-project --cli-input-json file://project-def.json > /dev/null
    else
        echo "Creating new CodeBuild project: $project_name"
        aws codebuild create-project --cli-input-json file://project-def.json > /dev/null
    fi
    
    # Clean up temporary file
    rm project-def.json
done

echo "CodeBuild projects created successfully."
