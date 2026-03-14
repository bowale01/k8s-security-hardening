# ============================================================================
# TERRAFORM VARIABLES: Configuration Options
# ============================================================================
# This file defines all configurable parameters for the security infrastructure.
# Customize these values in terraform.tfvars (copy from terraform.tfvars.example)
#
# Key variables:
# - aws_region: Where to deploy (us-east-1, eu-west-1, etc.)
# - cluster_name: Name of your EKS cluster
# - enable_* flags: Turn features on/off to control cost
#
# Cost optimization:
# - Set enable_service_mesh = false to save ~$30/month
# - Set enable_backup = false to save ~$50/month
# - Use smaller node_instance_types to save ~$30/month
#
# For production: Enable everything for maximum security
# For dev/test: Disable expensive features to reduce cost
# ============================================================================

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "security-demo"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "security-hardened-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_guardduty" {
  description = "Enable AWS GuardDuty for EKS"
  type        = bool
  default     = true
}

variable "enable_falco" {
  description = "Enable Falco runtime security"
  type        = bool
  default     = true
}

variable "enable_kyverno" {
  description = "Enable Kyverno policy engine"
  type        = bool
  default     = true
}

variable "node_instance_types" {
  description = "EC2 instance types for worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "enable_service_mesh" {
  description = "Enable Istio service mesh"
  type        = bool
  default     = true
}

variable "enable_external_secrets" {
  description = "Enable External Secrets Operator"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable Velero backup solution"
  type        = bool
  default     = true
}

variable "enable_oidc_provider" {
  description = "Enable OIDC identity provider"
  type        = bool
  default     = true
}

variable "enable_aws_sso" {
  description = "Enable AWS IAM Identity Center (SSO)"
  type        = bool
  default     = false
}

variable "oidc_admin_group" {
  description = "OIDC group name for cluster admins"
  type        = string
  default     = "k8s-admins"
}

variable "oidc_developer_group" {
  description = "OIDC group name for developers"
  type        = string
  default     = "k8s-developers"
}

variable "oidc_auditor_group" {
  description = "OIDC group name for auditors"
  type        = string
  default     = "k8s-auditors"
}

variable "enable_waf" {
  description = "Enable AWS WAF for ingress protection"
  type        = bool
  default     = true
}

variable "enable_geo_blocking" {
  description = "Enable geographic blocking in WAF"
  type        = bool
  default     = false
}

variable "blocked_countries" {
  description = "List of country codes to block (e.g., ['CN', 'RU'])"
  type        = list(string)
  default     = []
}

variable "waf_rate_limit" {
  description = "WAF rate limit per IP (requests per 5 minutes)"
  type        = number
  default     = 2000
}

variable "grafana_admin_password" {
  description = "Grafana admin dashboard password - keep this secret, never commit to git"
  type        = string
  sensitive   = true
}
