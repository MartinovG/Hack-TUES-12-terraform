variable "environment" {
  description = "Environment identifier (e.g. dev, stage, prod)"
  type        = string
}

variable "app_name" {
  description = "Logical application name used in resource naming"
  type        = string
}


variable "instance_type" {
  description = "EC2 instance type for bastion host"
  type        = string
  default     = "t2.micro" // free tier eligible
}


variable "bastion_sg_id" {
  description = "Security group ID for bastion host (from VPC module)"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs (bastion will use first one)"
  type        = list(string)
}
