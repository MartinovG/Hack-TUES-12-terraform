skip = true

terraform {
  source = "../../../modules/monitoring"
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
    github_connection_arn = null
    account_id            = "123456789012"
    region                = "us-east-1"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    nat_gateway_ids = ["nat-00000000000000000"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "ecs" {
  config_path = "../ecs"
  mock_outputs = {
    cluster_name    = "stage-hack-tues-12-cluster"
    alb_arn         = "arn:aws:elasticloadbalancing:us-east-1:000000000000:loadbalancer/app/stage-placeholder/0000000000000000"
    frontend_tg_arn = "arn:aws:elasticloadbalancing:us-east-1:000000000000:targetgroup/stage-placeholder/0000000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "postgres" {
  config_path = "../postgres"
  mock_outputs = {
    instance_id = "hack-tues-12-stage-postgres"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  app_name         = local.app_name
  environment      = local.environment
  region           = dependency.common.outputs.region
  alarm_emails     = local.parent_locals.locals.notification_emails
  ecs_cluster_name = dependency.ecs.outputs.cluster_name
  ecs_services = {
    "frontend" = "${local.environment}-${local.app_name}-frontend-service-public"
    "backend"  = "${local.environment}-${local.app_name}-backend-service-public"
  }
  alb_arn                 = dependency.ecs.outputs.alb_arn
  alb_target_group_arn    = dependency.ecs.outputs.frontend_tg_arn
  postgres_instance_id    = dependency.postgres.outputs.instance_id
  nat_gateway_ids         = dependency.vpc.outputs.nat_gateway_ids
  request_count_threshold = 10000
}
