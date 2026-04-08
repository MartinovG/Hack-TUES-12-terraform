# variable "environment" { description = "Environment" }
# variable "app_name" { description = "Application name" }
# variable "vpc_id" { description = "Target VPC ID" }
# variable "private_subnet_ids" {
#   type        = list(string)
#   description = "Private subnet IDs for association"
# }
# variable "client_cidr" {
#   description = "CIDR assigned to VPN clients"
#   default     = "10.250.0.0/22"
# }
# variable "server_certificate_arn" { description = "ACM ARN for the VPN server certificate" }
# variable "client_certificate_arn" { description = "ACM ARN for the client certificate (for mutual auth)" }
# variable "authorization_security_group_id" { description = "Security group ID granting access to DocumentDB" }
# variable "docdb_port" {
#   description = "DocumentDB port"
#   default     = 27017
# }
# variable "vpc_cidr" {
#   description = "VPC CIDR for routing"
# }