#!/bin/bash

set -e

echo "🚨 WARNING: This will destroy and recreate all Terraform-managed infrastructure!"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "❌ Aborted."
  exit 1
fi

echo "🔻 Destroying infrastructure..."
terraform destroy -auto-approve

echo "📦 Rebuilding Lambda ZIP (optional step if needed)..."
# Uncomment if you dynamically zip your Lambda code each time
# zip remediate_openssh_lambda.zip lambda_function.py

echo "🚀 Re-applying infrastructure..."
terraform apply -auto-approve

echo "✅ Terraform apply completed!"
echo "📍 Validating deployed resources..."
terraform show

echo "✨ Done. Your environment has been fully reset!"

