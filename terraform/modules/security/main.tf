data "aws_eks_cluster_auth" "main" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_cert)
  token                  = data.aws_eks_cluster_auth.main.token
}

provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_ca_cert)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

# Kyverno - Policy Engine
resource "helm_release" "kyverno" {
  name             = "kyverno"
  repository       = "https://kyverno.github.io/kyverno/"
  chart            = "kyverno"
  namespace        = "kyverno"
  create_namespace = true
  version          = "3.1.0"

  values = [
    yamlencode({
      admissionController = {
        replicas = 2
      }
      backgroundController = {
        enabled = true
      }
      cleanupController = {
        enabled = true
      }
      reportsController = {
        enabled = true
      }
    })
  ]
}

# Falco - Runtime Security
resource "helm_release" "falco" {
  name             = "falco"
  repository       = "https://falcosecurity.github.io/charts"
  chart            = "falco"
  namespace        = "falco"
  create_namespace = true
  version          = "4.0.0"

  values = [
    yamlencode({
      falco = {
        grpc = {
          enabled = true
        }
        grpcOutput = {
          enabled = true
        }
      }
      falcosidekick = {
        enabled = true
        webui = {
          enabled = true
        }
      }
    })
  ]
}

# Trivy Operator - Vulnerability Scanning
resource "helm_release" "trivy_operator" {
  name             = "trivy-operator"
  repository       = "https://aquasecurity.github.io/helm-charts/"
  chart            = "trivy-operator"
  namespace        = "trivy-system"
  create_namespace = true
  version          = "0.20.0"

  values = [
    yamlencode({
      trivy = {
        ignoreUnfixed = true
      }
    })
  ]
}

# Namespace for security tools
resource "kubernetes_namespace" "security" {
  metadata {
    name = "security-tools"
    labels = {
      "pod-security.kubernetes.io/enforce" = "restricted"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}
