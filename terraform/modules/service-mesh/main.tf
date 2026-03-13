# ============================================================================
# SERVICE MESH MODULE - Istio for mTLS and Zero Trust
# ============================================================================
# Deploys Istio service mesh providing:
# - Automatic mutual TLS between all services (encrypted communication)
# - Zero-trust networking (deny-all authorization by default)
# - Traffic management (circuit breaking, retries, timeouts)
# - Observability (distributed tracing, metrics)
#
# Why this matters:
# - OWASP K07: Prevents lateral movement after breach
# - NIST 800-190: Encrypts all service-to-service traffic
# - No code changes required - automatic sidecar injection
# - Stops man-in-the-middle attacks within the cluster
#
# How it works:
# 1. Istio injects a sidecar proxy into every pod
# 2. All traffic goes through the proxy
# 3. Proxy enforces mTLS and authorization policies
# 4. Services can't talk to each other without valid certificates
# ============================================================================

# Istio Service Mesh for mTLS and advanced traffic management
resource "helm_release" "istio_base" {
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  namespace        = "istio-system"
  create_namespace = true
  version          = "1.20.0"
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = "istio-system"
  version    = "1.20.0"

  values = [
    yamlencode({
      global = {
        # NIST 800-190: Enforce mTLS
        mtls = {
          enabled = true
        }
      }
      pilot = {
        resources = {
          requests = {
            cpu    = "500m"
            memory = "2048Mi"
          }
        }
      }
      # CIS: Enable security features
      meshConfig = {
        accessLogFile = "/dev/stdout"
        enableTracing = true
      }
    })
  ]

  depends_on = [helm_release.istio_base]
}

resource "helm_release" "istio_ingress" {
  name       = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = "istio-ingress"
  create_namespace = true
  version    = "1.20.0"

  depends_on = [helm_release.istiod]
}

# Enforce strict mTLS across the mesh
resource "kubernetes_manifest" "peer_authentication" {
  manifest = {
    apiVersion = "security.istio.io/v1beta1"
    kind       = "PeerAuthentication"
    metadata = {
      name      = "default"
      namespace = "istio-system"
    }
    spec = {
      mtls = {
        mode = "STRICT"
      }
    }
  }

  depends_on = [helm_release.istiod]
}

# Authorization policy - deny all by default
resource "kubernetes_manifest" "authz_policy_deny_all" {
  manifest = {
    apiVersion = "security.istio.io/v1beta1"
    kind       = "AuthorizationPolicy"
    metadata = {
      name      = "deny-all"
      namespace = "istio-system"
    }
    spec = {}
  }

  depends_on = [helm_release.istiod]
}
