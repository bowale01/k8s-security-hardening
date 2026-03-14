variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "grafana_admin_password" {
  description = "Grafana admin password - use a strong password and keep it secret"
  type        = string
  sensitive   = true
}
