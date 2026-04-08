output "web_acl_id" {
  description = "The ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.id
}

output "web_acl_arn" {
  description = "The ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.arn
}

output "web_acl_capacity" {
  description = "The capacity of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.capacity
}

output "log_group_name" {
  description = "The name of the CloudWatch log group for WAF logs"
  value       = aws_cloudwatch_log_group.waf_logs.name
}
