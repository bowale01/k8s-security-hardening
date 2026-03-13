# File Guide - What Each File Does

## Quick Reference

Every file now has detailed comments at the top explaining:
- **What it does** - Purpose and functionality
- **Why it matters** - Security benefit and compliance mapping
- **How it works** - Technical implementation details
- **Real-world impact** - Attack scenarios prevented

## Key Files Explained

### Terraform Infrastructure

#### `terraform/main.tf`
**What**: Orchestrates all 11 security modules
**Why**: Creates complete hardened infrastructure
**Look for**: Module declarations with detailed comments

#### `terraform/variables.tf`
**What**: Configuration options for customization
**Why**: Control features and costs
**Look for**: enable_* flags to turn features on/off

#### `terraform/modules/eks/main.tf`
**What**: Creates CIS-hardened EKS cluster
**Why**: Secure Kubernetes control plane
**Key features**: Audit logging, encryption, IMDSv2

#### `terraform/modules/vpc/main.tf`
**What**: Network isolation infrastructure
**Why**: Prevents direct attacks on nodes
**Key features**: Private subnets, NAT gateways

#### `terraform/modules/service-mesh/main.tf`
**What**: Istio for automatic mTLS
**Why**: Encrypts all service-to-service traffic
**Key features**: Zero-trust, deny-all default

#### `terraform/modules/secrets-management/main.tf`
**What**: External Secrets Operator
**Why**: No secrets in Git or Kubernetes
**Key features**: AWS Secrets Manager, auto-rotation

#### `terraform/modules/backup/main.tf`
**What**: Velero automated backups
**Why**: Disaster recovery capability
**Key features**: Daily/weekly backups, cross-region

#### `terraform/modules/monitoring/main.tf`
**What**: Prometheus/Grafana/Loki stack
**Why**: Security observability
**Key features**: Metrics, dashboards, log aggregation

#### `terraform/modules/identity/main.tf`
**What**: OIDC/SSO integration
**Why**: Centralized access control
**Key features**: Group-based RBAC, MFA ready

#### `terraform/modules/waf/main.tf`
**What**: Web Application Firewall
**Why**: Protects ingress from web attacks
**Key features**: OWASP Top 10, rate limiting

### Kubernetes Policies

#### `policies/kyverno/disallow-privileged.yaml`
**What**: Blocks privileged containers
**Why**: Prevents container escape attacks
**CIS**: 5.2.1 | **OWASP**: K01

#### `policies/kyverno/require-non-root.yaml`
**What**: Forces non-root user
**Why**: Limits damage from compromise
**CIS**: 5.2.6 | **OWASP**: K01

#### `policies/kyverno/require-resource-limits.yaml`
**What**: Requires CPU/memory limits
**Why**: Prevents resource exhaustion
**CIS**: 5.2.13 | **OWASP**: K01

#### `policies/network/default-deny-all.yaml`
**What**: Blocks all traffic by default
**Why**: Zero-trust networking
**CIS**: 5.3.1 | **OWASP**: K07

#### `policies/supply-chain/image-provenance.yaml`
**What**: Requires signed images
**Why**: Prevents malicious images
**OWASP**: K02 | **NIST**: 800-190

### RBAC

#### `rbac/least-privilege-role.yaml`
**What**: Example minimal permissions role
**Why**: Demonstrates least-privilege
**OWASP**: K03 | **CIS**: 5.1.1

### Compliance

#### `compliance/kube-bench-job.yaml`
**What**: CIS Benchmark audit job
**Why**: Validates 100+ security controls
**Use**: Run after deployment to verify compliance

### Scripts

#### `scripts/deploy.sh`
**What**: Automated deployment script
**Why**: One-command deployment
**Time**: 15-20 minutes
**Result**: Fully hardened cluster

#### `scripts/destroy.sh`
**What**: Complete cleanup script
**Why**: Remove all infrastructure
**Time**: 10-15 minutes
**Result**: $0/month cost

#### `scripts/validate-100-percent.sh`
**What**: Validates all security controls
**Why**: Proves 100% coverage
**Checks**: CIS, OWASP, NIST requirements

## Documentation Files

### `INTERVIEW-GUIDE.md`
**Purpose**: Complete interview preparation
**Contains**:
- Elevator pitch
- 11 layers explained in detail
- Q&A for common interview questions
- Real-world attack scenarios
- Key metrics to mention
- Demo flow

### `PROJECT-SUMMARY.md`
**Purpose**: Executive overview
**Contains**:
- What's been created
- Coverage achieved
- Cost breakdown
- Deployment instructions

### `README.md`
**Purpose**: Main project documentation
**Contains**:
- Architecture overview
- How each component works
- Quick start guide
- Interview talking points

### `docs/100-percent-coverage.md`
**Purpose**: Detailed coverage matrix
**Contains**:
- CIS Benchmark: 100% coverage table
- OWASP K8s Top 10: All 10 risks
- NIST 800-190: All categories
- Before/after comparison

### `docs/security-controls.md`
**Purpose**: All security controls explained
**Contains**:
- Control plane security
- Worker node security
- Network security
- Workload security
- Supply chain security

### `docs/deployment-guide.md`
**Purpose**: Step-by-step deployment
**Contains**:
- Prerequisites
- Deployment steps
- Verification procedures
- Troubleshooting

### `docs/quick-start.md`
**Purpose**: 5-minute quick start
**Contains**:
- Minimal steps to deploy
- Quick verification
- Access dashboards

## How to Read the Code

### 1. Start with Comments
Every file has a header block explaining:
```
# ============================================================================
# FILE PURPOSE
# ============================================================================
# What this does: ...
# Why this matters: ...
# How it works: ...
```

### 2. Look for Security Annotations
Policies include:
- **CIS Control**: Which benchmark requirement
- **OWASP**: Which Top 10 risk
- **NIST**: Which 800-190 category
- **Real-world impact**: Attack prevented

### 3. Follow the Layers
Infrastructure is built in order:
1. VPC (network isolation)
2. KMS (encryption)
3. EKS (control plane)
4. Service Mesh (mTLS)
5. Security Tools (enforcement)
6. Secrets Management
7. Backup/DR
8. Monitoring
9. Identity
10. GuardDuty
11. WAF

### 4. Understand Dependencies
Modules depend on each other:
- EKS needs VPC and KMS
- Security tools need EKS
- Service mesh needs EKS
- Everything needs VPC

## For Interview Preparation

### Files to Know Well
1. **INTERVIEW-GUIDE.md** - Your main study guide
2. **terraform/main.tf** - Shows all 11 layers
3. **policies/kyverno/** - Policy enforcement examples
4. **README.md** - Architecture and flow

### Files to Skim
1. **docs/100-percent-coverage.md** - Coverage details
2. **docs/security-controls.md** - Control mapping
3. **terraform/modules/** - Implementation details

### Files to Reference
1. **PROJECT-SUMMARY.md** - Quick facts
2. **docs/cost-estimate.md** - Cost numbers
3. **scripts/** - Deployment process

## Common Questions

### "What does this file do?"
→ Read the header comment block (lines 1-20)

### "Why is this needed?"
→ Look for "Why this matters" section

### "What attack does this prevent?"
→ Look for "Real-world impact" section

### "Which compliance requirement?"
→ Look for CIS/OWASP/NIST annotations

### "How do I use this?"
→ Look for "How to use" section

## Tips for Interviews

### When Showing Code
1. Open the file
2. Read the header comment
3. Explain the "Why this matters"
4. Give the "Real-world impact" example
5. Show the implementation

### When Explaining Architecture
1. Start with the 11 layers diagram
2. Pick a layer (e.g., Service Mesh)
3. Open the module file
4. Read the header comment
5. Explain how it fits in the overall security

### When Discussing Compliance
1. Open a policy file
2. Point to the CIS/OWASP annotation
3. Explain what it prevents
4. Show how it's enforced

All files are now self-documenting with detailed comments!
