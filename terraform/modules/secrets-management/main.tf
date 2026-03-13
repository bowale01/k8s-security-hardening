# ============================================================================
# SECRETS MANAGEMENT MODULE - External Secrets Operator
# ============================================================================
# Implements secure secrets management with:
# - External Secrets Operator (fetches from AWS Secrets Manager)
# - Automatic rotation every 30 days via Lambda
# - No secrets stored in Kubernetes or Git
# - IAM Roles for Service Accounts (temporary credentials)
#
# Why this matters:
# - OWASP K08: Secrets Management Failures
# - Prevents hardcoded credentials in code
# - Automatic rotation reduces risk of credential theft
# - Audit trail of all secret access
#
# How it works:
# 1. Application requests secret via Kubernetes Secret object
# 2. External Secrets Operator fetches from AWS Secrets Manager
# 3. Secret is injected into pod at runtime
# 4. Lambda rotates secret every 30 days
# 5. Operator automatically updates Kubernetes secret
# 6. Pods get new secret on next restart (rolling update)
# ============================================================================

# External Secrets Operator for dynamic secrets management
resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets-system"
  create_namespace = true
  version          = "0.9.11"

  values = [
    yamlencode({
      installCRDs = true
      webhook = {
        port = 9443
      }
      certController = {
        enabled = true
      }
    })
  ]
}

# IAM role for External Secrets Operator
resource "aws_iam_role" "external_secrets" {
  name = "${var.cluster_name}-external-secrets"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${var.oidc_provider}:sub" = "system:serviceaccount:external-secrets-system:external-secrets"
          "${var.oidc_provider}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

# Policy for accessing AWS Secrets Manager
resource "aws_iam_role_policy" "external_secrets" {
  name = "external-secrets-policy"
  role = aws_iam_role.external_secrets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:${var.cluster_name}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = var.kms_key_arn
      }
    ]
  })
}

# Service Account for External Secrets
resource "kubernetes_service_account" "external_secrets" {
  metadata {
    name      = "external-secrets"
    namespace = "external-secrets-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_secrets.arn
    }
  }

  depends_on = [helm_release.external_secrets]
}

# SecretStore for AWS Secrets Manager
resource "kubernetes_manifest" "secret_store" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "aws-secrets-manager"
    }
    spec = {
      provider = {
        aws = {
          service = "SecretsManager"
          region  = var.aws_region
          auth = {
            jwt = {
              serviceAccountRef = {
                name      = "external-secrets"
                namespace = "external-secrets-system"
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.external_secrets,
    kubernetes_service_account.external_secrets
  ]
}

# Secrets rotation Lambda
resource "aws_lambda_function" "secrets_rotation" {
  filename      = "${path.module}/lambda/secrets-rotation.zip"
  function_name = "${var.cluster_name}-secrets-rotation"
  role          = aws_iam_role.lambda_rotation.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 30

  environment {
    variables = {
      CLUSTER_NAME = var.cluster_name
    }
  }
}

resource "aws_iam_role" "lambda_rotation" {
  name = "${var.cluster_name}-lambda-rotation"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_rotation.name
}

# EventBridge rule for automatic rotation (every 30 days)
resource "aws_cloudwatch_event_rule" "secrets_rotation" {
  name                = "${var.cluster_name}-secrets-rotation"
  description         = "Trigger secrets rotation every 30 days"
  schedule_expression = "rate(30 days)"
}

resource "aws_cloudwatch_event_target" "secrets_rotation" {
  rule      = aws_cloudwatch_event_rule.secrets_rotation.name
  target_id = "SecretsRotation"
  arn       = aws_lambda_function.secrets_rotation.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secrets_rotation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.secrets_rotation.arn
}
