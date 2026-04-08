terraform {
  source = "../../../modules/vpc"
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

dependency "common" {
  config_path = "../common"
  mock_outputs = {
    github_connection_arn = "arn:aws:codestar-connections:us-east-1:123456789012:connection/00000000-0000-0000-0000-000000000000"
    account_id            = "123456789012"
    region                = "us-east-1"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  region                         = dependency.common.outputs.region
  environment                    = local.environment
  app_name                       = local.app_name
  vpc_cidr                       = local.parent_locals.locals.vpc_cidr
  public_subnets_cidr            = local.parent_locals.locals.public_subnets_cidr
  private_subnets_cidr           = local.parent_locals.locals.private_subnets_cidr
  codebuild_private_subnets_cidr = local.parent_locals.locals.codebuild_private_subnets_cidr
  availability_zones             = local.parent_locals.locals.availability_zones
  service                        = local.service
  core_app                       = local.core_app
  frontend                       = local.frontend
}
