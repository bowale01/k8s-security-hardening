variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID"
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
  description = "KMS key ARN for secrets encryption"
  type        = string
}
