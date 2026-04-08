terraform {
  source = "../../../modules/bastion"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    bastion_sg_id      = "sg-bastionplaceholder"
    private_subnet_ids = ["subnet-aaaa", "subnet-bbbb", "subnet-cccc"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

locals {
  parent_locals = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  environment   = local.parent_locals.locals.environment
  app_name      = local.parent_locals.locals.app_name
  instance_type = local.parent_locals.locals.bastion_instance_type
}

inputs = {
  environment        = local.environment
  app_name           = local.app_name
  bastion_sg_id      = dependency.vpc.outputs.bastion_sg_id
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  instance_type      = local.instance_type
}
