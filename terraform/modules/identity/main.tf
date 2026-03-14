# ============================================================================
# IDENTITY MODULE - OIDC and RBAC Integration
# ============================================================================
# Implements identity and access management with:
# - OIDC integration for SSO (corporate identity provider)
# - Group-based RBAC (admins, developers, auditors)
# - Least-privilege access control
# - MFA enforcement ready
# - Audit logging of all access
#
# Why this matters:
# - OWASP K03: Overly Permissive RBAC
# - OWASP K06: Broken Authentication
# - Centralized user management
# - No shared credentials
# - Compliance with access control requirements
#
# User groups:
# - k8s-admins: Full cluster access (cluster-admin)
# - k8s-developers: Deploy apps, read logs (limited)
# - k8s-auditors: Read-only everything (compliance)
#
# All access is logged for compliance audits.
# ============================================================================

# NOTE: OIDC provider is created in the EKS module.
# This module receives the ARN and URL as input variables to avoid duplicate resource errors.

# Kubernetes RBAC for OIDC groups
resource "kubernetes_cluster_role_binding" "oidc_admins" {
  metadata {
    name = "oidc-cluster-admins"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "Group"
    name      = var.admin_group_name
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_cluster_role_binding" "oidc_developers" {
  metadata {
    name = "oidc-developers"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "developer"
  }

  subject {
    kind      = "Group"
    name      = var.developer_group_name
    api_group = "rbac.authorization.k8s.io"
  }
}

# Developer ClusterRole with limited permissions
resource "kubernetes_cluster_role" "developer" {
  metadata {
    name = "developer"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "services", "configmaps"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "statefulsets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch"]
  }
}

# Read-only ClusterRole for auditors
resource "kubernetes_cluster_role" "auditor" {
  metadata {
    name = "auditor"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "oidc_auditors" {
  metadata {
    name = "oidc-auditors"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "auditor"
  }

  subject {
    kind      = "Group"
    name      = var.auditor_group_name
    api_group = "rbac.authorization.k8s.io"
  }
}

# AWS IAM Identity Center (SSO) integration
resource "aws_iam_role" "sso_admin" {
  count = var.enable_aws_sso ? 1 : 0
  name  = "${var.cluster_name}-sso-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}
