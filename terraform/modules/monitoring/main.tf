# ============================================================================
# MONITORING MODULE - Prometheus, Grafana, Loki Stack
# ============================================================================
# Implements comprehensive observability with:
# - Prometheus: Metrics collection and alerting
# - Grafana: Visualization dashboards
# - Loki: Log aggregation and search
# - AlertManager: Incident notifications
# - CloudWatch: AWS service integration
#
# Why this matters:
# - OWASP K05: Inadequate Logging and Monitoring
# - Detects security incidents in real-time
# - Provides forensics data for investigations
# - Enables proactive threat hunting
#
# What gets monitored:
# - Security policy violations
# - Failed authentication attempts
# - Unusual network traffic
# - Resource exhaustion
# - Container anomalies
# - API abuse
#
# Retention: 30 days for metrics, 30 days for logs
# ============================================================================

# CloudWatch Log Group for EKS
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 30

  tags = {
    Name        = "${var.cluster_name}-logs"
    Environment = var.environment
  }
}

# CloudWatch Alarms for security events
resource "aws_cloudwatch_metric_alarm" "unauthorized_api_calls" {
  alarm_name          = "${var.cluster_name}-unauthorized-api-calls"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnauthorizedAPICalls"
  namespace           = "EKS/Security"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alert on unauthorized API calls"
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "pod_security_violations" {
  alarm_name          = "${var.cluster_name}-pod-security-violations"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "PodSecurityViolations"
  namespace           = "EKS/Security"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alert on Pod Security Standard violations"
  treat_missing_data  = "notBreaching"
}

# Prometheus Stack
resource "helm_release" "prometheus" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  version          = "55.0.0"

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention = "30d"
          resources = {
            requests = {
              cpu    = "500m"
              memory = "2Gi"
            }
          }
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "50Gi"
                  }
                }
              }
            }
          }
        }
      }
      grafana = {
        enabled = true
        adminPassword = var.grafana_admin_password
        persistence = {
          enabled = true
          size    = "10Gi"
        }
        dashboardProviders = {
          "dashboardproviders.yaml" = {
            apiVersion = 1
            providers = [
              {
                name    = "default"
                orgId   = 1
                folder  = ""
                type    = "file"
                options = {
                  path = "/var/lib/grafana/dashboards/default"
                }
              }
            ]
          }
        }
      }
      alertmanager = {
        enabled = true
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "10Gi"
                  }
                }
              }
            }
          }
        }
      }
    })
  ]
}

# Loki for log aggregation
resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki-stack"
  namespace        = "monitoring"
  create_namespace = true
  version          = "2.10.0"

  values = [
    yamlencode({
      loki = {
        enabled = true
        persistence = {
          enabled = true
          size    = "50Gi"
        }
      }
      promtail = {
        enabled = true
      }
      grafana = {
        enabled = false # Already installed above
      }
    })
  ]

  depends_on = [helm_release.prometheus]
}
