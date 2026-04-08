skip = true

terraform {
  source = "../../../modules/acm-vpn"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  parent_locals = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  environment   = local.parent_locals.locals.environment
  app_name      = local.parent_locals.locals.app_name
  main_domain   = local.parent_locals.locals.main_domain
}

inputs = {
  environment       = local.environment
  app_name          = local.app_name
  vpn_server_domain = "vpn-server.${local.app_name}.${local.main_domain}"
  vpn_client_domain = "vpn-client.${local.app_name}.${local.main_domain}"
}
