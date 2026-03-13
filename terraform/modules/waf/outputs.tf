output "waf_acl_arn" {
  description = "WAF WebACL ARN"
  value       = aws_wafv2_web_acl.main.arn
}

output "waf_acl_id" {
  description = "WAF WebACL ID"
  value       = aws_wafv2_web_acl.main.id
}

output "waf_logs_bucket" {
  description = "S3 bucket for WAF logs"
  value       = aws_s3_bucket.waf_logs.id
}
