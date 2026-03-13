output "istio_ingress_gateway_ip" {
  description = "Istio ingress gateway load balancer IP"
  value       = helm_release.istio_ingress.status
}

output "istiod_version" {
  description = "Istio control plane version"
  value       = helm_release.istiod.version
}
