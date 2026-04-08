variable "environment" {
  description = "Environment identifier (e.g. dev, stage, prod)"
  type        = string
}
variable "app_name" {
  description = "Logical application name used in resource naming"
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
  description = "Primary DNS domain (e.g. innovatebulgaria.com)"
  type        = string
}
variable "manual_approval" {
  description = "Whether or not to create a manual approval stage. Used in production"
  type        = bool
}

variable "service" {
  description = "Map of microservice definitions"
  type = map(object({
    repo_short    = string
    repo_long     = string
    branch        = string
    port          = number
    external_port = number
  }))
}
variable "core_app" {
  description = "Map of core app service definition(s)"
  type = map(object({
    repo_short    = string
    repo_long     = string
    branch        = string
    port          = number
    external_port = number
  }))
}
variable "frontend" {
  description = "Map of frontend service definition(s)"
  type = map(object({
    repo_short          = string
    repo_long           = string
    branch              = string
    port                = number
    external_http_port  = number
    external_https_port = number
  }))
}

variable "github_connection_arn" {
  description = "GitHub CodeStar connection ARN"
  type        = string
}

variable "core_app_task_arn_without_revision" {
  description = "Map of core app task definition ARNs without revision"
  type        = map(string)
}
variable "frontend_task_arn_without_revision" {
  description = "Map of frontend task definition ARNs without revision"
  type        = map(string)
}
variable "service_task_arn_without_revision" {
  description = "Map of microservice task definition ARNs without revision"
  type        = map(string)
}

variable "ecs_sg_id" {
  description = "ECS security group ID"
  type        = string
}
variable "private_subnet_a_id" {
  description = "Private subnet A ID"
  type        = string
}
variable "private_subnet_b_id" {
  description = "Private subnet B ID"
  type        = string
}
variable "private_subnet_c_id" {
  description = "Private subnet C ID"
  type        = string
}
variable "codebuild_sg_id" {
  description = "CodeBuild security group ID"
  type        = string
}
variable "codebuild_private_subnet_ids" {
  description = "List of private subnet IDs for CodeBuild VPC config"
  type        = list(string)
}
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}