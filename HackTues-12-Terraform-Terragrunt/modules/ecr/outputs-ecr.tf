output "core_app_repos" {
  value = { for k, v in aws_ecr_repository.core_app : k => {
    name = v.name
    arn  = v.arn
    url  = v.repository_url
  } }
}

output "service_repos" {
  value = { for k, v in aws_ecr_repository.service : k => {
    name = v.name
    arn  = v.arn
    url  = v.repository_url
  } }
}

output "frontend_repos" {
  value = { for k, v in aws_ecr_repository.frontend : k => {
    name = v.name
    arn  = v.arn
    url  = v.repository_url
  } }
}