# Deployment Guide

## Prerequisites

### Required Tools
```bash
# Terraform
terraform --version  # >= 1.5

# kubectl
kubectl version --client  # >= 1.28

# AWS CLI
aws --version  # >= 2.0

# Helm
helm version  # >= 3.12
```

### AWS Credentials
```bash
# Configure AWS CLI
aws configure

# Verify access
aws sts get-caller-identity
```

## Step-by-Step Deployment

### 1. Clone and Configure
```bash
cd k8s-security-hardening/terraform
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your settings
vim terraform.tfvars
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Review Plan
```bash
terraform plan
```

Expected resources:
- VPC with 3 public and 3 private subnets
- EKS cluster with encrypted secrets
- 2 worker nodes (t3.medium)
- KMS key for encryption
- GuardDuty detector
- CloudWatch log groups
- Security tools (Kyverno, Falco, Trivy)

### 4. Deploy Infrastructure
```bash
terraform apply
```

This will take 15-20 minutes.

### 5. Configure kubectl
```bash
aws eks update-kubeconfig --name security-hardened-cluster --region us-east-1
kubectl get nodes
```

### 6. Apply Security Policies
```bash
# Pod Security Standards
kubectl label namespace default \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted

# Network Policies
kubectl apply -f ../policies/network/

# Kyverno Policies (wait for Kyverno to be ready)
sleep 30
kubectl apply -f ../policies/kyverno/

# RBAC
kubectl apply -f ../rbac/
```

### 7. Run Compliance Audit
```bash
kubectl apply -f ../compliance/kube-bench-job.yaml
kubectl logs -n security-tools job/kube-bench
```

### 8. Verify Security Tools
```bash
# Check Kyverno
kubectl get clusterpolicies

# Check Falco
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=50

# Check Trivy
kubectl get vulnerabilityreports -A

# Check GuardDuty (AWS Console)
aws guardduty list-detectors
```

## Post-Deployment

### Monitor Security Events
```bash
# Falco alerts
kubectl logs -n falco -l app.kubernetes.io/name=falco -f

# Kyverno policy reports
kubectl get policyreports -A

# GuardDuty findings
aws guardduty list-findings --detector-id <detector-id>
```

### Test Security Controls
```bash
# Try to create privileged pod (should fail)
kubectl run test --image=nginx --privileged=true

# Try to create pod without resource limits (should fail)
kubectl run test --image=nginx

# Create compliant pod
kubectl run test --image=nginx \
  --overrides='{"spec":{"securityContext":{"runAsNonRoot":true,"runAsUser":1000},"containers":[{"name":"test","image":"nginx","resources":{"limits":{"cpu":"100m","memory":"128Mi"},"requests":{"cpu":"50m","memory":"64Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"readOnlyRootFilesystem":true}}]}}'
```

## Troubleshooting

### Terraform Issues
```bash
# State lock issues
terraform force-unlock <lock-id>

# Refresh state
terraform refresh

# Import existing resources
terraform import <resource> <id>
```

### Cluster Access Issues
```bash
# Update kubeconfig
aws eks update-kubeconfig --name security-hardened-cluster --region us-east-1

# Check IAM permissions
aws sts get-caller-identity
aws eks describe-cluster --name security-hardened-cluster
```

### Policy Enforcement Issues
```bash
# Check Kyverno status
kubectl get pods -n kyverno

# View policy violations
kubectl get policyreports -A

# Check admission webhook
kubectl get validatingwebhookconfigurations
```

## Cleanup

### Destroy Everything
```bash
# Option 1: Use script
bash scripts/destroy.sh

# Option 2: Manual
cd terraform
terraform destroy
```

### Partial Cleanup
```bash
# Remove security tools only
helm uninstall kyverno -n kyverno
helm uninstall falco -n falco
helm uninstall trivy-operator -n trivy-system

# Keep infrastructure running
```

## Cost Management

### Monitor Costs
```bash
# AWS Cost Explorer
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --filter file://cost-filter.json
```

### Reduce Costs
1. Scale down nodes: `kubectl scale deployment --replicas=1`
2. Use spot instances for non-prod
3. Disable GuardDuty when not testing
4. Reduce log retention period
5. Destroy when not in use

## Next Steps

1. Integrate with CI/CD pipeline
2. Set up automated compliance reporting
3. Configure incident response playbooks
4. Implement secrets rotation
5. Add service mesh (Istio/Linkerd)
6. Set up centralized logging (ELK/Splunk)
