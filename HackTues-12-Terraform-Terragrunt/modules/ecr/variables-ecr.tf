variable "environment" {
  description = "Environment"
}

variable "app_name" {
  description = "The name of the application"
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
