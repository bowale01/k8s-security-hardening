output "backup_bucket" {
  description = "S3 bucket for Velero backups"
  value       = aws_s3_bucket.velero.id
}

output "velero_role_arn" {
  description = "IAM role ARN for Velero"
  value       = aws_iam_role.velero.arn
}
