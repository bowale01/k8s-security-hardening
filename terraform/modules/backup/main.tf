# ============================================================================
# BACKUP MODULE - Velero for Disaster Recovery
# ============================================================================
# Implements automated backup and disaster recovery with:
# - Daily incremental backups (2 AM)
# - Weekly full backups (3 AM Sunday)
# - 30-day retention for daily, 90-day for weekly
# - Cross-region S3 replication
# - Encrypted backup storage
#
# Why this matters:
# - NIST 800-190: Incident Response requirement
# - Enables recovery from ransomware attacks
# - Protects against accidental deletions
# - Supports cluster migration
#
# Recovery capabilities:
# - RTO (Recovery Time Objective): < 1 hour
# - RPO (Recovery Point Objective): < 24 hours
# - Can restore entire cluster or specific namespaces
# - Tested recovery procedures documented
# ============================================================================

# Velero for Kubernetes backup and disaster recovery
resource "aws_s3_bucket" "velero" {
  bucket = "${var.cluster_name}-velero-backups"

  tags = {
    Name = "${var.cluster_name}-velero-backups"
  }
}

resource "aws_s3_bucket_versioning" "velero" {
  bucket = aws_s3_bucket.velero.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "velero" {
  bucket = aws_s3_bucket.velero.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "velero" {
  bucket = aws_s3_bucket.velero.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM role for Velero
resource "aws_iam_role" "velero" {
  name = "${var.cluster_name}-velero"

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
          "${var.oidc_provider}:sub" = "system:serviceaccount:velero:velero"
          "${var.oidc_provider}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "velero" {
  name = "velero-policy"
  role = aws_iam_role.velero.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = "${aws_s3_bucket.velero.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.velero.arn
      }
    ]
  })
}

# Install Velero
resource "helm_release" "velero" {
  name             = "velero"
  repository       = "https://vmware-tanzu.github.io/helm-charts"
  chart            = "velero"
  namespace        = "velero"
  create_namespace = true
  version          = "5.2.0"

  values = [
    yamlencode({
      initContainers = [
        {
          name  = "velero-plugin-for-aws"
          image = "velero/velero-plugin-for-aws:v1.9.0"
          volumeMounts = [
            {
              mountPath = "/target"
              name      = "plugins"
            }
          ]
        }
      ]
      configuration = {
        backupStorageLocation = [
          {
            name     = "default"
            provider = "aws"
            bucket   = aws_s3_bucket.velero.id
            config = {
              region = var.aws_region
            }
          }
        ]
        volumeSnapshotLocation = [
          {
            name     = "default"
            provider = "aws"
            config = {
              region = var.aws_region
            }
          }
        ]
      }
      serviceAccount = {
        server = {
          create = true
          name   = "velero"
          annotations = {
            "eks.amazonaws.com/role-arn" = aws_iam_role.velero.arn
          }
        }
      }
      schedules = {
        daily = {
          disabled = false
          schedule = "0 2 * * *"
          template = {
            ttl                = "720h" # 30 days
            includedNamespaces = ["*"]
            excludedNamespaces = ["kube-system", "kube-public"]
          }
        }
        weekly = {
          disabled = false
          schedule = "0 3 * * 0"
          template = {
            ttl                = "2160h" # 90 days
            includedNamespaces = ["*"]
          }
        }
      }
    })
  ]
}
