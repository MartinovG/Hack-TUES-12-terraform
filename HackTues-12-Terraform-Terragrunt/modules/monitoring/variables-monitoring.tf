variable "app_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "alarm_emails" {
  description = "List of email addresses to receive alarm notifications"
  type        = list(string)
  default     = []
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
  default     = ""
}

variable "ecs_services" {
  description = "Map of ECS service names (key: short name, value: full service name)"
  type        = map(string)
  default     = {}
}

variable "alb_arn" {
  description = "ALB ARN"
  type        = string
  default     = ""
}

variable "alb_target_group_arn" {
  description = "ALB target group ARN"
  type        = string
  default     = ""
}

variable "postgres_instance_id" {
  description = "PostgreSQL RDS instance identifier"
  type        = string
  default     = ""
}

variable "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  type        = list(string)
  default     = []
}

variable "request_count_threshold" {
  description = "Threshold for total request count alarm (requests per 5-minute period)"
  type        = number
}
