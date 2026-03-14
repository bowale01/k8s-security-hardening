variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "EKS cluster OIDC issuer URL (full URL with https://)"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider (created in EKS module)"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL without https:// prefix"
  type        = string
}

variable "admin_group_name" {
  description = "OIDC group name for cluster admins"
  type        = string
  default     = "k8s-admins"
}

variable "developer_group_name" {
  description = "OIDC group name for developers"
  type        = string
  default     = "k8s-developers"
}

variable "auditor_group_name" {
  description = "OIDC group name for auditors"
  type        = string
  default     = "k8s-auditors"
}

variable "enable_aws_sso" {
  description = "Enable AWS IAM Identity Center (SSO) integration"
  type        = bool
  default     = false
}
