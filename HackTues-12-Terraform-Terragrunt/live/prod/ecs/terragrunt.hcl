skip = true

terraform { source = "../../../modules/ecs" }
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

# Dependency blocks with mock outputs to allow validate/plan without having applied upstream units yet.
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
    vpc_id             = "vpc-mock"
    private_subnet_ids = ["subnet-mock1", "subnet-mock2"]
    public_subnet_ids  = ["subnet-mock3", "subnet-mock4"]
    alb_sg_id          = "sg-mock-alb"
    ecs_sg_id          = "sg-mock-ecs"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "acm" {
  config_path = "../acm"
  mock_outputs = {
    certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "ecr" {
  config_path = "../ecr"
  mock_outputs = {
    core_app_repos = {
      backend = {
        name = "mock-backend-repo"
        arn  = "arn:aws:ecr:us-east-1:123456789012:repository/mock"
        url  = "123456789012.dkr.ecr.us-east-1.amazonaws.com/mock-backend"
      }
    }
    service_repos = {}
    frontend_repos = {
      frontend = {
        name = "mock-frontend-repo"
        arn  = "arn:aws:ecr:us-east-1:123456789012:repository/mock"
        url  = "123456789012.dkr.ecr.us-east-1.amazonaws.com/mock-frontend"
      }
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "postgres" {
  config_path = "../postgres"
  mock_outputs = {
    database_url = "postgresql://mock:mock@mock:5432/mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  environment        = local.environment
  app_name           = local.app_name
  main_domain        = local.main_domain
  region             = dependency.common.outputs.region
  account_id         = dependency.common.outputs.account_id
  database_url       = dependency.postgres.outputs.database_url
  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  public_subnet_ids  = dependency.vpc.outputs.public_subnet_ids
  alb_sg_id          = dependency.vpc.outputs.alb_sg_id
  ecs_sg_id          = dependency.vpc.outputs.ecs_sg_id
  certificate_arn    = dependency.acm.outputs.certificate_arn
  service            = local.service
  core_app           = local.core_app
  frontend           = local.frontend
  # Explicit maps (avoid key/value for-expr incompatibility with Terragrunt config parser)
  core_app_ecr_url = { backend = dependency.ecr.outputs.core_app_repos.backend.url }
  frontend_ecr_url = { frontend = dependency.ecr.outputs.frontend_repos.frontend.url }
  service_ecr_url  = {}
}
