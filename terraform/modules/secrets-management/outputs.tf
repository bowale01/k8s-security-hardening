output "external_secrets_role_arn" {
  description = "IAM role ARN for External Secrets Operator"
  value       = aws_iam_role.external_secrets.arn
}

output "secrets_rotation_function_arn" {
  description = "Lambda function ARN for secrets rotation"
  value       = aws_lambda_function.secrets_rotation.arn
}
