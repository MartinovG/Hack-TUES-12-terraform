terraform {
  source = "../../../modules/route53-zone"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  parent_locals = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  app_name      = local.parent_locals.locals.app_name
  main_domain   = local.parent_locals.locals.main_domain
}

inputs = {
  app_name    = local.app_name
  main_domain = local.main_domain
}
