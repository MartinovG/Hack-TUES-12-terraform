skip = true

terraform {
  source = "../../../modules/postgres"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "common" {
  config_path = "../common"
  mock_outputs = {
    github_connection_arn = null
    account_id            = "123456789012"
    region                = "us-east-1"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    private_subnet_ids = ["subnet-000", "subnet-001", "subnet-002"]
    postgres_sg_id     = "sg-000"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

locals {
  parent_locals = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  environment   = local.parent_locals.locals.environment
  app_name      = local.parent_locals.locals.app_name
}

inputs = {
  environment         = local.environment
  app_name            = local.app_name
  account_id          = dependency.common.outputs.account_id
  private_subnet_ids  = dependency.vpc.outputs.private_subnet_ids
  postgres_sg_id      = dependency.vpc.outputs.postgres_sg_id
  notification_emails = local.parent_locals.locals.notification_emails
}
