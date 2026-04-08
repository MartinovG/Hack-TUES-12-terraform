variable "app_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the ALB to associate with the WAF Web ACL"
  type        = string
}

variable "blocked_countries" {
  description = "List of country codes to block (ISO 3166-1 alpha-2 codes, e.g., ['CN', 'RU']). Empty list means no geo-blocking."
  type        = list(string)
  default     = []
}
