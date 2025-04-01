#!/bin/bash
# Script to set up EKS Pod Identity for ECR access in Auto Mode clusters

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

# Get cluster name
echo "Fetching EKS cluster name..."
CLUSTER_NAME=$(aws eks list-clusters --query "clusters[0]" --output text)
if [ -z "$CLUSTER_NAME" ]; then
    echo "Error: No EKS cluster found. Please specify your cluster name:"
    read -p "Cluster name: " CLUSTER_NAME
fi

echo "Using EKS cluster: $CLUSTER_NAME"

# Create IAM policy for ECR access if it doesn't exist
POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='EcrPullPolicy'].Arn" --output text)
    
if [ -z "$POLICY_ARN" ]; then
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

# Create IAM role if it doesn't exist
ROLE_ARN=$(aws iam list-roles --query "Roles[?RoleName=='EcrPullRole'].Arn" --output text)

if [ -z "$ROLE_ARN" ]; then
    echo "Creating IAM role for EKS Pod Identity..."
    
    # Create trust policy document
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

    # Create the role
    ROLE_ARN=$(aws iam create-role \
        --role-name EcrPullRole \
        --assume-role-policy-document file:///tmp/trust-policy.json \
        --query "Role.Arn" --output text)
    
    # Attach the policy to the role
    aws iam attach-role-policy \
        --role-name EcrPullRole \
        --policy-arn "$POLICY_ARN"
    
    echo "Created role with ARN: $ROLE_ARN"
else
    echo "Using existing IAM role: $ROLE_ARN"
fi

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
