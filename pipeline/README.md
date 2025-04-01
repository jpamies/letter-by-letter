# CI/CD Pipeline for Letter-by-Letter Image Generator

This directory contains CloudFormation templates to set up a complete CI/CD pipeline for the Letter-by-Letter Image Generator application on AWS.

## Pipeline Architecture

The pipeline uses the following AWS services:

- **AWS CodeCommit**: Git repository to store the application code
- **AWS CodeBuild**: Build service to create Docker images for each microservice
- **AWS CodePipeline**: Orchestration service to manage the CI/CD workflow
- **Amazon ECR**: Container registry to store the Docker images

## Pipeline Workflow

1. Code is pushed to the CodeCommit repository
2. CodePipeline detects changes and triggers the pipeline
3. Source code is pulled from CodeCommit
4. CodeBuild builds Docker images for each service (frontend, orchestrator, compositor)
5. Images are pushed to Amazon ECR repositories

## Deployment Instructions

### Prerequisites

- AWS CLI installed and configured with appropriate permissions
- An AWS account with access to create the required resources

### Deploying the Pipeline

1. Deploy the CloudFormation stack:

```bash
aws cloudformation create-stack \
  --stack-name letter-image-generator-pipeline \
  --template-body file://pipeline.yaml \
  --capabilities CAPABILITY_IAM \
  --parameters \
    ParameterKey=RepositoryName,ParameterValue=letter-image-generator \
    ParameterKey=BranchName,ParameterValue=main \
    ParameterKey=ProjectName,ParameterValue=letter-image-generator
```

2. After the stack is created, get the CodeCommit repository URL:

```bash
aws cloudformation describe-stacks \
  --stack-name letter-image-generator-pipeline \
  --query "Stacks[0].Outputs[?OutputKey=='CodeCommitRepositoryUrl'].OutputValue" \
  --output text
```

3. Push your code to the CodeCommit repository:

```bash
# Add the CodeCommit repository as a remote
git remote add codecommit <CODECOMMIT_REPO_URL>

# Push your code to CodeCommit
git push codecommit main
```

4. The pipeline will automatically start once code is pushed to the repository.

## Monitoring the Pipeline

You can monitor the pipeline in the AWS Management Console:

1. Open the AWS CodePipeline console
2. Select the `letter-image-generator-pipeline`
3. View the pipeline execution status and details

## ECR Repository URIs

After the stack is created, you can get the ECR repository URIs using:

```bash
aws cloudformation describe-stacks \
  --stack-name letter-image-generator-pipeline \
  --query "Stacks[0].Outputs[?starts_with(OutputKey, 'EcrRepository')].{Key:OutputKey,Value:OutputValue}" \
  --output table
```

Use these URIs to pull the images for deployment to EKS.
