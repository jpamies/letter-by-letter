#!/bin/bash
# Script to set up EKS Pod Identity for ECR access in Auto Mode clusters

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if AWS credentials are configured
echo "Checking AWS authentication..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS authentication failed. Please configure your AWS credentials."
    echo "You can configure AWS credentials using one of the following methods:"
    echo "1. Run 'aws configure' to set up credentials"
    echo "2. Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables"
    echo "3. Use an AWS profile with 'export AWS_PROFILE=your-profile-name'"
    exit 1
fi

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Get AWS region
AWS_REGION=$(aws configure get region)
if [ -z "$AWS_REGION" ]; then
    echo "Error: AWS region not found. Please configure AWS CLI with a default region."
    exit 1
fi

# Get cluster name
echo "Fetching EKS cluster name..."
CLUSTER_NAME=$(aws eks list-clusters --query "clusters[0]" --output text)
if [ -z "$CLUSTER_NAME" ] || [ "$CLUSTER_NAME" == "None" ]; then
    echo "No EKS cluster found automatically. Please enter your cluster name:"
    read -p "Cluster name: " CLUSTER_NAME
    if [ -z "$CLUSTER_NAME" ]; then
        echo "Error: No cluster name provided. Exiting."
        exit 1
    fi
fi

echo "Using EKS cluster: $CLUSTER_NAME"

# Create IAM policy for ECR access if it doesn't exist
POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='EcrPullPolicy'].Arn" --output text)
    
if [ -z "$POLICY_ARN" ] || [ "$POLICY_ARN" == "None" ]; then
    echo "Creating ECR pull policy..."
    POLICY_ARN=$(aws iam create-policy \
        --policy-name EcrPullPolicy \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": [
                        "ecr:GetDownloadUrlForLayer",
                        "ecr:BatchGetImage",
                        "ecr:BatchCheckLayerAvailability"
                    ],
                    "Resource": "arn:aws:ecr:*:*:repository/*"
                },
                {
                    "Effect": "Allow",
                    "Action": "ecr:GetAuthorizationToken",
                    "Resource": "*"
                }
            ]
        }' --query "Policy.Arn" --output text)
    
    echo "Created policy with ARN: $POLICY_ARN"
else
    echo "Using existing ECR pull policy: $POLICY_ARN"
fi

# Create a simple trust policy for EKS Pod Identity
cat > /tmp/trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "pods.eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create or update IAM role
ROLE_NAME="EcrPullRole-${CLUSTER_NAME}"
ROLE_ARN=$(aws iam list-roles --query "Roles[?RoleName=='${ROLE_NAME}'].Arn" --output text)

if [ -z "$ROLE_ARN" ] || [ "$ROLE_ARN" == "None" ]; then
    echo "Creating IAM role for EKS Pod Identity..."
    
    # Create the role
    ROLE_ARN=$(aws iam create-role \
        --role-name "${ROLE_NAME}" \
        --assume-role-policy-document file:///tmp/trust-policy.json \
        --query "Role.Arn" --output text)
    
    # Attach the policy to the role
    aws iam attach-role-policy \
        --role-name "${ROLE_NAME}" \
        --policy-arn "$POLICY_ARN"
    
    echo "Created role with ARN: $ROLE_ARN"
else
    echo "Updating existing IAM role: $ROLE_ARN"
    aws iam update-assume-role-policy \
        --role-name "${ROLE_NAME}" \
        --policy-document file:///tmp/trust-policy.json
    
    # Ensure policy is attached
    aws iam attach-role-policy \
        --role-name "${ROLE_NAME}" \
        --policy-arn "$POLICY_ARN"
fi

# Create namespace if it doesn't exist
echo "Creating namespace if it doesn't exist..."
kubectl get namespace letter-image-generator &> /dev/null || kubectl create namespace letter-image-generator

# Create service account if it doesn't exist
echo "Creating Kubernetes service account..."
kubectl get serviceaccount ecr-pull-sa -n letter-image-generator 2>/dev/null || \
kubectl create serviceaccount ecr-pull-sa -n letter-image-generator

# Create Pod Identity Association
echo "Creating EKS Pod Identity Association..."
aws eks create-pod-identity-association \
    --cluster-name "$CLUSTER_NAME" \
    --namespace letter-image-generator \
    --service-account ecr-pull-sa \
    --role-arn "$ROLE_ARN" || \
echo "Pod Identity Association may already exist or there was an error. Continuing..."

echo "EKS Pod Identity setup complete!"
echo "Now update your deployments to use serviceAccountName: ecr-pull-sa"
