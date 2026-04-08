variable "environment" {
  description = "Environment"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "postgres_sg_id" {
  description = "Security group ID attached to PostgreSQL"
  type        = string
}

variable "notification_emails" {
  description = "Emails for PostgreSQL event notifications"
  type        = list(string)
  default     = []
}
