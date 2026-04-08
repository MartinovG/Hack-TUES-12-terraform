terraform {
  source = "../../../modules/acm"
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

dependency "route53_zone" {
  config_path = "../route53-zone"
  mock_outputs = {
    zone_id   = "Z0000000000000000000"
    zone_name = "hack-tues-12.innovatebulgaria.com"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  environment      = local.environment
  app_name         = local.app_name
  main_domain      = local.main_domain
  hosted_zone_id   = dependency.route53_zone.outputs.zone_id
  hosted_zone_name = dependency.route53_zone.outputs.zone_name
}
