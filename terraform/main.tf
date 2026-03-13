# ============================================================================
# MAIN TERRAFORM CONFIGURATION
# ============================================================================
# This is the orchestration file that ties all security modules together.
# It creates a fully hardened Kubernetes cluster with 100% CIS/OWASP/NIST compliance.
# 
# What this file does:
# - Defines required Terraform and provider versions
# - Calls 11 security modules in the correct order
# - Passes configuration between modules
# - Outputs important information after deployment
# ============================================================================

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }

  backend "s3" {
    # Configure your S3 backend here for remote state storage
    # This allows team collaboration and state locking
    # bucket = "your-terraform-state-bucket"
    # key    = "k8s-security/terraform.tfstate"
    # region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "K8s-Security-Hardening"
      ManagedBy   = "Terraform"
      Environment = var.environment
      CostCenter  = "Security"
    }
  }
}

# ============================================================================
# LAYER 1: NETWORK INFRASTRUCTURE (VPC)
# ============================================================================
# Creates isolated network with public/private subnets across 3 availability zones.
# Worker nodes run in private subnets with no direct internet access.
# This is the foundation - prevents direct attacks on nodes.
# ============================================================================
module "vpc" {
  source = "./modules/vpc"

  cluster_name = var.cluster_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

# ============================================================================
# LAYER 3: KUBERNETES CONTROL PLANE (EKS)
# ============================================================================
# Creates CIS-hardened EKS cluster with:
# - All audit logs enabled (tracks every API call)
# - Secrets encrypted at rest with KMS
# - IMDSv2 enforced (prevents credential theft)
# - OIDC provider for IAM integration
# This is the brain of Kubernetes - must be secured first.
# ============================================================================
module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  environment     = var.environment

  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets

  # CIS 3.2.1: Enable comprehensive audit logging
  # Logs every API call for compliance and forensics
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # CIS 3.1.1: Encrypt secrets at rest
  # Uses AWS KMS so stolen etcd data is useless
  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = module.kms.key_arn
  }
}

# ============================================================================
# LAYER 2: ENCRYPTION (KMS)
# ============================================================================
# Creates and manages encryption keys for:
# - Kubernetes secrets in etcd
# - EBS volumes (node storage)
# - S3 backups
# - Automatic key rotation enabled
# CIS 3.1.1 requirement - protects data at rest.
# ============================================================================
module "kms" {
  source = "./modules/kms"

  cluster_name = var.cluster_name
  environment  = var.environment
}

# ============================================================================
# LAYER 5: WORKLOAD SECURITY (Policy Enforcement)
# ============================================================================
# Deploys security enforcement tools:
# - Kyverno: 20+ admission policies (blocks bad pods before they start)
# - Falco: Runtime threat detection (detects suspicious behavior)
# - Trivy: Vulnerability scanning (blocks images with critical CVEs)
# OWASP K01, K02, K04 - Multiple layers of workload protection.
# ============================================================================
module "security_tools" {
  source = "./modules/security"

  cluster_name     = var.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_ca_cert  = module.eks.cluster_certificate_authority_data

  depends_on = [module.eks]
}

# GuardDuty for EKS
module "guardduty" {
  source = "./modules/guardduty"

  cluster_name = var.cluster_name
  environment  = var.environment

  depends_on = [module.eks]
}

# CloudWatch and Prometheus monitoring
module "monitoring" {
  source = "./modules/monitoring"

  cluster_name = var.cluster_name
  environment  = var.environment

  depends_on = [module.eks]
}

# ============================================================================
# LAYER 4: NETWORK SECURITY (Service Mesh)
# ============================================================================
# Deploys Istio service mesh for:
# - Automatic mTLS between all services (encrypted communication)
# - Zero-trust networking (deny-all by default)
# - Traffic management and observability
# OWASP K07 - Prevents lateral movement and data exfiltration.
# ============================================================================
module "service_mesh" {
  count  = var.enable_service_mesh ? 1 : 0
  source = "./modules/service-mesh"

  cluster_name = var.cluster_name
  enable_istio = var.enable_service_mesh

  depends_on = [module.eks]
}

# External Secrets Management
module "secrets_management" {
  count  = var.enable_external_secrets ? 1 : 0
  source = "./modules/secrets-management"

  cluster_name      = var.cluster_name
  aws_region        = var.aws_region
  aws_account_id    = data.aws_caller_identity.current.account_id
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider     = module.eks.oidc_provider_url
  kms_key_arn       = module.kms.key_arn

  depends_on = [module.eks]
}

# Backup and Disaster Recovery (Velero)
module "backup" {
  count  = var.enable_backup ? 1 : 0
  source = "./modules/backup"

  cluster_name      = var.cluster_name
  aws_region        = var.aws_region
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider     = module.eks.oidc_provider_url
  kms_key_arn       = module.kms.key_arn

  depends_on = [module.eks]
}

# Identity and Access Management
module "identity" {
  count  = var.enable_oidc_provider ? 1 : 0
  source = "./modules/identity"

  cluster_name            = var.cluster_name
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  admin_group_name        = var.oidc_admin_group
  developer_group_name    = var.oidc_developer_group
  auditor_group_name      = var.oidc_auditor_group
  enable_aws_sso          = var.enable_aws_sso

  depends_on = [module.eks]
}

# Web Application Firewall
module "waf" {
  count  = var.enable_waf ? 1 : 0
  source = "./modules/waf"

  cluster_name       = var.cluster_name
  enable_geo_blocking = var.enable_geo_blocking
  blocked_countries  = var.blocked_countries
  rate_limit         = var.waf_rate_limit

  depends_on = [module.eks]
}

data "aws_caller_identity" "current" {}
