skip = true

# Pipeline is intentionally disabled for the Hack TUES 12 stack for now.
terraform { source = "../../../modules/cicd-ecs" }
include "root" { path = find_in_parent_folders("root.hcl") }

locals {
  parent_locals = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  environment   = local.parent_locals.locals.environment
  app_name      = local.parent_locals.locals.app_name
  main_domain   = local.parent_locals.locals.main_domain
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

dependency "ecr" {
  config_path = "../ecr"
  mock_outputs = {
    ecr_repository_urls = {
      "backend"    = "123456789012.dkr.ecr.us-east-1.amazonaws.com/backend"
      "algorithms" = "123456789012.dkr.ecr.us-east-1.amazonaws.com/algorithms"
      "frontend"   = "123456789012.dkr.ecr.us-east-1.amazonaws.com/frontend"
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}
dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id                       = "vpc-00000000000000000"
    private_subnet_ids           = ["subnet-aaaa", "subnet-bbbb", "subnet-cccc"]
    codebuild_private_subnet_ids = ["subnet-dddd", "subnet-eeee", "subnet-ffff"]
    ecs_sg_id                    = "sg-ecsplaceholder"
    codebuild_sg_id              = "sg-codebuildplaceholder"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}
dependency "ecs" {
  config_path = "../ecs"
  mock_outputs = {
    cluster_name                       = "route-optimizer-dev"
    core_app_task_arn_without_revision = { backend = "arn:aws:ecs:us-east-1:123456789012:task-definition/dev-route-optimizer-backend" }
    frontend_task_arn_without_revision = { frontend = "arn:aws:ecs:us-east-1:123456789012:task-definition/dev-route-optimizer-frontend" }
    service_task_arn_without_revision  = { algorithms = "arn:aws:ecs:us-east-1:123456789012:task-definition/dev-route-optimizer-algorithms" }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  environment           = local.environment
  app_name              = local.app_name
  account_id            = dependency.common.outputs.account_id
  region                = dependency.common.outputs.region
  main_domain           = local.main_domain
  manual_approval       = false
  service               = local.service
  core_app              = local.core_app
  frontend              = local.frontend
  github_connection_arn = dependency.common.outputs.github_connection_arn
  # Task definition family ARNs without revision from ECS dependency
  core_app_task_arn_without_revision = dependency.ecs.outputs.core_app_task_arn_without_revision
  frontend_task_arn_without_revision = dependency.ecs.outputs.frontend_task_arn_without_revision
  service_task_arn_without_revision  = dependency.ecs.outputs.service_task_arn_without_revision
  # Networking and security from VPC dependency
  ecs_sg_id                    = dependency.vpc.outputs.ecs_sg_id
  private_subnet_a_id          = dependency.vpc.outputs.private_subnet_ids[0]
  private_subnet_b_id          = dependency.vpc.outputs.private_subnet_ids[1]
  private_subnet_c_id          = dependency.vpc.outputs.private_subnet_ids[2]
  codebuild_sg_id              = dependency.vpc.outputs.codebuild_sg_id
  codebuild_private_subnet_ids = dependency.vpc.outputs.codebuild_private_subnet_ids
  vpc_id                       = dependency.vpc.outputs.vpc_id
}
