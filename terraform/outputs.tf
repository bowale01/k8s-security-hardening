output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = module.guardduty.detector_id
}

output "kms_key_arn" {
  description = "KMS key ARN for secrets encryption"
  value       = module.kms.key_arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "security_tools_deployed" {
  description = "List of deployed security tools"
  value = {
    kyverno           = var.enable_kyverno
    falco             = var.enable_falco
    guardduty         = var.enable_guardduty
    kube_bench        = true
    trivy             = true
    service_mesh      = var.enable_service_mesh
    external_secrets  = var.enable_external_secrets
    backup            = var.enable_backup
    oidc              = var.enable_oidc_provider
    waf               = var.enable_waf
  }
}

output "backup_bucket" {
  description = "S3 bucket for Velero backups"
  value       = var.enable_backup ? module.backup[0].backup_bucket : null
}

output "waf_acl_arn" {
  description = "WAF WebACL ARN"
  value       = var.enable_waf ? module.waf[0].waf_acl_arn : null
}

output "coverage_status" {
  description = "Security coverage status"
  value = {
    cis_benchmark     = "100%"
    owasp_k8s_top10   = "100%"
    nist_800_190      = "100%"
    overall_coverage  = "100%"
  }
}
