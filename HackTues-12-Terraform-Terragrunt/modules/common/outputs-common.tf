output "github_connection_arn" {
  description = "ARN of the CodeStar connection to GitHub"
  value       = length(data.aws_codestarconnections_connection.github) > 0 ? data.aws_codestarconnections_connection.github[0].arn : null
}

output "account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "AWS Region"
  # Use the 'region' attribute to avoid deprecation warning on 'name'
  value = data.aws_region.current.region
}
