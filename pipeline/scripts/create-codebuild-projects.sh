#!/bin/bash

# This script creates CodeBuild projects for the Letter-by-Letter Image Generator services

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Set default values
PROJECT_NAME="letter-image-generator"
REGION="eu-south-2"
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

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

echo "Creating CodeBuild projects for: $PROJECT_NAME in region $REGION"

# Create IAM role for CodeBuild
echo "Creating IAM role for CodeBuild..."
ROLE_NAME="${PROJECT_NAME}-codebuild-role"

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

# Create policy document
cat > policy.json << EOF
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
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObject"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Create IAM role
aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://trust-policy.json
aws iam put-role-policy --role-name $ROLE_NAME --policy-name "${PROJECT_NAME}-codebuild-policy" --policy-document file://policy.json

# Clean up temporary files
rm trust-policy.json policy.json

# Wait for role to be available
echo "Waiting for IAM role to be available..."
sleep 10

# Create CodeBuild projects for each service
for service in "frontend" "orchestrator" "compositor"; do
    build_project_name="${PROJECT_NAME}-${service}-build"
    echo "Creating CodeBuild project: $build_project_name"
    
    # Create buildspec file
    cat > buildspec.json << EOF
{
  "version": "0.2",
  "phases": {
    "pre_build": {
      "commands": [
        "echo Logging in to Amazon ECR...",
        "aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com",
        "COMMIT_HASH=\$(echo \$CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)",
        "IMAGE_TAG=\${COMMIT_HASH:=latest}"
      ]
    },
    "build": {
      "commands": [
        "echo Building the Docker image...",
        "cd $service",
        "docker build -t $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${PROJECT_NAME}-${service}:latest .",
        "docker tag $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${PROJECT_NAME}-${service}:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${PROJECT_NAME}-${service}:\$IMAGE_TAG"
      ]
    },
    "post_build": {
      "commands": [
        "echo Pushing the Docker image...",
        "docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${PROJECT_NAME}-${service}:latest",
        "docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${PROJECT_NAME}-${service}:\$IMAGE_TAG",
        "echo Writing image definitions file...",
        "echo {\\"ImageURI\\":\\"\$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${PROJECT_NAME}-${service}:\$IMAGE_TAG\\"} > imageDefinition.json"
      ]
    }
  },
  "artifacts": {
    "files": [
      "imageDefinition.json",
      "appspec.yml",
      "taskdef.json"
    ]
  }
}
EOF

    # Create CodeBuild project
    aws codebuild create-project \
      --name $build_project_name \
      --description "Build project for the $service service" \
      --service-role "arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME" \
      --artifacts type=NO_ARTIFACTS \
      --environment "type=LINUX_CONTAINER,computeType=BUILD_GENERAL1_SMALL,image=aws/codebuild/amazonlinux2-x86_64-standard:3.0,privilegedMode=true" \
      --source "type=CODECOMMIT,location=https://git-codecommit.eu-west-1.amazonaws.com/v1/repos/$PROJECT_NAME,buildspec=$(cat buildspec.json)" \
      --region $REGION
done

# Clean up temporary files
rm buildspec.json

echo "CodeBuild projects created successfully."
