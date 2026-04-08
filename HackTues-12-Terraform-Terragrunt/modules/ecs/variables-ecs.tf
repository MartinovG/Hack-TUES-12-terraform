variable "environment" {
  description = "Environment"
  type        = string
}
variable "app_name" {
  description = "The name of the application"
  type        = string
}
variable "account_id" {
  description = "AWS Account ID (from common module)"
  type        = string
}
variable "region" {
  description = "AWS Region (from common module)"
  type        = string
}
variable "main_domain" {
  description = "Main domain"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone id used for the public ALB DNS record"
  type        = string
}
variable "database_url" {
  description = "PostgreSQL connection string"
  type        = string
}

variable "service" {
  description = "Microservices map"
  type = map(object({
    repo_short    = string
    repo_long     = string
    branch        = string
    port          = number
    external_port = number
  }))
  default = {}
}

variable "core_app" {
  description = "Core app map"
  type = map(object({
    repo_short    = string
    repo_long     = string
    branch        = string
    port          = number
    external_port = number
  }))
  default = {}
}

variable "frontend" {
  description = "Frontend map"
  type = map(object({
    repo_short          = string
    repo_long           = string
    branch              = string
    port                = number
    external_http_port  = number
    external_https_port = number
  }))
  default = {}
}

variable "core_app_ecr_url" {
  description = "Map of core app ECR repository URLs, keyed by service name"
  type        = map(string)
}

variable "core_app_image_tag" {
  description = "Map of core app image tags, keyed by service name"
  type        = map(string)
  default     = {}
}

variable "frontend_ecr_url" {
  description = "Map of frontend ECR repository URLs, keyed by service name"
  type        = map(string)
}

variable "frontend_image_tag" {
  description = "Map of frontend image tags, keyed by service name"
  type        = map(string)
  default     = {}
}

variable "service_ecr_url" {
  description = "Map of microservice ECR repository URLs, keyed by service name"
  type        = map(string)
}


variable "ecs_sg_id" {
  description = "ECS security group ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "ALB Security Group ID"
  type        = string
}

variable "certificate_arn" {
  description = "ACM Certificate ARN"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}
