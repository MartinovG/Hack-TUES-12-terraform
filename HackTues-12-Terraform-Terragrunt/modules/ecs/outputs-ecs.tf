// ECS module outputs for downstream dependencies (e.g., CICD)

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main_cluster.name
}

// Task definition ARNs without revision (family form) for CodeBuild deploy steps
output "core_app_task_arn_without_revision" {
  description = "Map of core app task definition family ARNs without revision"
  value = {
    for k, td in aws_ecs_task_definition.core_app_task :
    k => "arn:aws:ecs:${var.region}:${var.account_id}:task-definition/${td.family}"
  }
}

output "frontend_task_arn_without_revision" {
  description = "Map of frontend task definition family ARNs without revision"
  value = {
    for k, td in aws_ecs_task_definition.frontend_task :
    k => "arn:aws:ecs:${var.region}:${var.account_id}:task-definition/${td.family}"
  }
}

output "service_task_arn_without_revision" {
  description = "Map of service task definition family ARNs without revision"
  value = {
    for k, td in aws_ecs_task_definition.microservice_task :
    k => "arn:aws:ecs:${var.region}:${var.account_id}:task-definition/${td.family}"
  }
}

output "alb_arn" {
  description = "ARN of the public ALB"
  value       = aws_lb.public_alb.arn
}

output "frontend_tg_arn" {
  description = "ARN of the frontend target group"
  value       = aws_lb_target_group.public_alb_frontend_target_group["frontend"].arn
}

output "backend_listener_arn" {
  description = "ARN of the backend listener used by API Gateway"
  value       = try(aws_lb_listener.public_alb_listener_core_app["backend"].arn, null)
}

output "alb_dns_name" {
  description = "DNS name of the public ALB"
  value       = aws_lb.public_alb.dns_name
}
