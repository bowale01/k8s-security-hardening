#!/bin/bash
# ============================================================================
# DESTROY SCRIPT: Complete Infrastructure Cleanup
# ============================================================================
# What this script does:
# 1. Confirms you really want to destroy everything
# 2. Deletes all Kubernetes resources (namespaces, pods, etc.)
# 3. Runs terraform destroy to remove AWS infrastructure
# 4. Cleans up all resources
#
# Why this matters:
# - Stops all AWS charges (cost goes to $0)
# - Removes all infrastructure
# - Clean slate for redeployment
#
# How to use:
# bash scripts/destroy.sh
#
# What gets deleted:
# - EKS cluster
# - VPC and networking
# - Security tools
# - Backups (S3 buckets)
# - Monitoring stack
# - All AWS resources
#
# Time: 10-15 minutes
# Result: $0/month cost
#
# WARNING: This is irreversible! Make sure you have backups if needed.
# ============================================================================
set -e

echo "🗑️  Kubernetes Security Hardening Cleanup"
echo "========================================="
echo ""
echo "⚠️  WARNING: This will destroy all resources!"
echo ""
read -p "Are you sure you want to destroy everything? (type 'yes' to confirm): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled"
    exit 0
fi

cd terraform

# Get cluster name before destroying
CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "")

if [ -n "$CLUSTER_NAME" ]; then
    echo ""
    echo "🧹 Cleaning up Kubernetes resources..."
    
    # Delete all resources in security namespaces
    kubectl delete namespace security-tools --ignore-not-found=true
    kubectl delete namespace kyverno --ignore-not-found=true
    kubectl delete namespace falco --ignore-not-found=true
    kubectl delete namespace trivy-system --ignore-not-found=true
    
    echo "✅ Kubernetes resources cleaned up"
fi

echo ""
echo "💥 Destroying infrastructure with Terraform..."
terraform destroy -auto-approve

echo ""
echo "✅ All resources destroyed!"
echo ""
echo "💰 Cost savings: Infrastructure is now completely removed"
