#!/bin/bash
# ------------------------------------------------------
# Bootstrap Terraform S3 backend + DynamoDB lock table
# Compatible with Terraform >= 1.5, < 1.10
# Run once before terraform init
# Usage: ./scripts/bootstrap-backend.sh
# ------------------------------------------------------
set -euo pipefail

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="awx-platform-tf-state-${ACCOUNT_ID}"
TABLE="awx-platform-tf-locks"
REGION="us-east-1"

echo "=== Verifying AWS credentials ==="
aws sts get-caller-identity

# ------------------------------------------------------
# S3 Bucket
# ------------------------------------------------------
if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "=== Bucket already exists, skipping ==="
else
  echo "=== Creating S3 bucket: $BUCKET ==="
  aws s3api create-bucket \
    --bucket "$BUCKET" \
    --region "$REGION"
fi

# ------------------------------------------------------
# Versioning
# ------------------------------------------------------
VERSIONING=$(aws s3api get-bucket-versioning \
  --bucket "$BUCKET" \
  --query Status --output text 2>/dev/null || echo "None")

if [ "$VERSIONING" = "Enabled" ]; then
  echo "=== Versioning already enabled, skipping ==="
else
  echo "=== Enabling versioning ==="
  aws s3api put-bucket-versioning \
    --bucket "$BUCKET" \
    --versioning-configuration Status=Enabled
fi

# ------------------------------------------------------
# Encryption
# ------------------------------------------------------
if aws s3api get-bucket-encryption --bucket "$BUCKET" 2>/dev/null; then
  echo "=== Encryption already enabled, skipping ==="
else
  echo "=== Enabling encryption ==="
  aws s3api put-bucket-encryption \
    --bucket "$BUCKET" \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }]
    }'
fi

# ------------------------------------------------------
# Block public access
# ------------------------------------------------------
PUBLIC_ACCESS=$(aws s3api get-public-access-block \
  --bucket "$BUCKET" \
  --query 'PublicAccessBlockConfiguration.BlockPublicAcls' \
  --output text 2>/dev/null || echo "false")

if [ "$PUBLIC_ACCESS" = "true" ]; then
  echo "=== Public access block already set, skipping ==="
else
  echo "=== Blocking public access ==="
  aws s3api put-public-access-block \
    --bucket "$BUCKET" \
    --public-access-block-configuration \
      "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
fi

# ------------------------------------------------------
# DynamoDB lock table
# ------------------------------------------------------
if aws dynamodb describe-table --table-name "$TABLE" --region "$REGION" 2>/dev/null; then
  echo "=== DynamoDB table already exists, skipping ==="
else
  echo "=== Creating DynamoDB table: $TABLE ==="
  aws dynamodb create-table \
    --table-name "$TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"

  echo "=== Waiting for table to be active ==="
  aws dynamodb wait table-exists \
    --table-name "$TABLE" \
    --region "$REGION"
fi

echo ""
echo "=== Backend ready. Run: terraform init ==="