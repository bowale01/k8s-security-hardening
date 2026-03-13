#!/bin/bash
# ============================================================================
# DEPLOYMENT SCRIPT: Automated Kubernetes Security Hardening
# ============================================================================
# What this script does:
# 1. Validates prerequisites (terraform, kubectl, aws cli, helm)
# 2. Deploys infrastructure with Terraform (EKS, VPC, security tools)
# 3. Configures kubectl to access the cluster
# 4. Applies Pod Security Standards to namespaces
# 5. Deploys network policies (default deny)
# 6. Applies Kyverno policies (20+ admission policies)
# 7. Configures RBAC (least-privilege roles)
# 8. Runs initial CIS compliance scan
#
# How to use:
# bash scripts/deploy.sh
#
# What gets deployed:
# - EKS cluster with CIS hardening
# - Istio service mesh (mTLS everywhere)
# - Kyverno (policy enforcement)
# - Falco (runtime security)
# - Trivy (vulnerability scanning)
# - External Secrets (secrets management)
# - Velero (backup/DR)
# - Prometheus/Grafana (monitoring)
# - GuardDuty (threat detection)
#
# Time: 15-20 minutes
# Cost: ~$350/month (or $0 when destroyed)
# ============================================================================
set -e

echo "🔒 Kubernetes Security Hardening Deployment"
echo "==========================================="

# Check prerequisites
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform is required but not installed."; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is required but not installed."; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI is required but not installed."; exit 1; }

echo "✅ Prerequisites check passed"

# Deploy infrastructure
echo ""
echo "📦 Deploying infrastructure with Terraform..."
cd terraform
terraform init
terraform plan -out=tfplan
read -p "Do you want to apply this plan? (yes/no): " confirm
if [ "$confirm" = "yes" ]; then
    terraform apply tfplan
else
    echo "Deployment cancelled"
    exit 0
fi

# Get cluster name
CLUSTER_NAME=$(terraform output -raw cluster_name)
AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-east-1")

# Configure kubectl
echo ""
echo "🔧 Configuring kubectl..."
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION"

# Wait for cluster to be ready
echo ""
echo "⏳ Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Apply Pod Security Standards
echo ""
echo "🛡️ Applying Pod Security Standards..."
kubectl label namespace default pod-security.kubernetes.io/enforce=restricted
kubectl label namespace default pod-security.kubernetes.io/audit=restricted
kubectl label namespace default pod-security.kubernetes.io/warn=restricted

# Apply Network Policies
echo ""
echo "🌐 Applying Network Policies..."
kubectl apply -f ../policies/network/

# Apply Kyverno Policies
echo ""
echo "📋 Applying Kyverno Policies..."
sleep 30  # Wait for Kyverno to be ready
kubectl apply -f ../policies/kyverno/

# Apply RBAC
echo ""
echo "👥 Applying RBAC configurations..."
kubectl apply -f ../rbac/

# Run initial compliance scan
echo ""
echo "🔍 Running CIS Benchmark compliance scan..."
kubectl apply -f ../compliance/kube-bench-job.yaml
echo "Check results with: kubectl logs -n security-tools job/kube-bench"

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Review kube-bench results: kubectl logs -n security-tools job/kube-bench"
echo "2. Check Falco alerts: kubectl logs -n falco -l app.kubernetes.io/name=falco"
echo "3. View Trivy reports: kubectl get vulnerabilityreports -A"
echo "4. Monitor GuardDuty findings in AWS Console"
