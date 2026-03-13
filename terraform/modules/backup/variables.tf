variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  type        = string
}

variable "oidc_provider" {
  description = "OIDC provider URL"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for backup encryption"
  type        = string
}
