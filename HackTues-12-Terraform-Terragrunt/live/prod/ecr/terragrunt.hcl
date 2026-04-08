skip = true

terraform {
  source = "../../../modules/ecr"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  parent_locals = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  environment   = local.parent_locals.locals.environment
  app_name      = local.parent_locals.locals.app_name
  service       = local.parent_locals.locals.service
  core_app      = local.parent_locals.locals.core_app
  frontend      = local.parent_locals.locals.frontend
}

inputs = {
  environment = local.environment
  app_name    = local.app_name
  service     = local.service
  core_app    = local.core_app
  frontend    = local.frontend
}
