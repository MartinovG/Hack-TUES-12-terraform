variable "environment" {
  description = "Environment"
}

variable "app_name" {
  description = "The name of the application"
}

variable "main_domain" {
  description = "The main PRODUCTION domin which hosted zone and subdomains will be created to"
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone id used for certificate validation"
  type        = string
}

variable "hosted_zone_name" {
  description = "Route53 hosted zone name used for certificate validation"
  type        = string
}
