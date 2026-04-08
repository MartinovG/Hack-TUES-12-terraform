skip = true

terraform {
  source = "../../../modules/waf"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  parent_locals = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  environment   = local.parent_locals.locals.environment
  app_name      = local.parent_locals.locals.app_name
}

dependency "common" {
  config_path = "../common"
  mock_outputs = {
    github_connection_arn = "arn:aws:codestar-connections:us-east-1:123456789012:connection/00000000-0000-0000-0000-000000000000"
    account_id            = "123456789012"
    region                = "us-east-1"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

# Link to ECS to fetch ALB ARN
dependency "ecs" {
  config_path = "../ecs"
  mock_outputs = {
    alb_arn = "arn:aws:elasticloadbalancing:us-east-1:000000000000:loadbalancer/app/dev-placeholder/0000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  app_name          = local.app_name
  environment       = local.environment
  region            = dependency.common.outputs.region
  alb_arn           = dependency.ecs.outputs.alb_arn
  blocked_countries = []
}
