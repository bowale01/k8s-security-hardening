variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "enable_istio" {
  description = "Enable Istio service mesh"
  type        = bool
  default     = true
}
