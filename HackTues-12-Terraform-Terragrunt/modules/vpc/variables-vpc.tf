variable "region" {
  type        = string
  description = "AWS region"
}

variable "environment" {
  description = "Deployment Environment"
}

variable "app_name" {
  description = "The name of the application"
}

variable "vpc_cidr" {
  description = "CIDR block of the vpc"
}

variable "public_subnets_cidr" {
  type        = list(any)
  description = "Public subnet CIDRs"
}

variable "private_subnets_cidr" {
  type        = list(any)
  description = "Private subnet CIDRs"
}

variable "codebuild_private_subnets_cidr" {
  type        = list(any)
  description = "CodeBuild subnet CIDRs"
}

variable "availability_zones" {
  type        = list(any)
  description = "AZ suffixes (e.g. a,b,c)"
}

variable "service" {
  description = "The info for each service"
  type = map(object({
    repo_short    = string
    repo_long     = string
    branch        = string
    port          = number
    external_port = number
  }))
}

variable "core_app" {
  description = "The info for Core app"
  type = map(object({
    repo_short    = string
    repo_long     = string
    branch        = string
    port          = number
    external_port = number
  }))
}

variable "frontend" {
  description = "The info for Frontend"
  type = map(object({
    repo_short          = string
    repo_long           = string
    branch              = string
    port                = number
    external_http_port  = number
    external_https_port = number
  }))
}