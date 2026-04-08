# terraform {
#   source = "../../../modules/vpn"
# }

# include "root" {
#   path = find_in_parent_folders("root.hcl")
# }

# dependency "vpc" {
#   config_path = "../vpc"
#   mock_outputs = {
#     vpc_id             = "vpc-000000"
#     private_subnet_ids = ["subnet-000", "subnet-001"]
#     vpc_cidr           = "10.64.0.0/16"
#     docdb_sg_id        = "sg-000"
#   }
#   mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
# }

# dependency "acm_vpn" {
#   config_path = "../acm-vpn"
#   mock_outputs = {
#     vpn_server_certificate_arn = "arn:aws:acm:us-east-1:536697243063:certificate/mock-server"
#     vpn_client_certificate_arn = "arn:aws:acm:us-east-1:536697243063:certificate/mock-client"
#   }
#   mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
# }

# locals {
#   parent_locals = read_terragrunt_config(find_in_parent_folders("root.hcl"))
#   environment   = local.parent_locals.locals.environment
#   app_name      = local.parent_locals.locals.app_name
# }

# inputs = {
#   environment                     = local.environment
#   app_name                        = local.app_name
#   vpc_id                          = dependency.vpc.outputs.vpc_id
#   private_subnet_ids              = dependency.vpc.outputs.private_subnet_ids
#   vpc_cidr                        = dependency.vpc.outputs.vpc_cidr
#   server_certificate_arn          = dependency.acm_vpn.outputs.vpn_server_certificate_arn
#   client_certificate_arn          = dependency.acm_vpn.outputs.vpn_client_certificate_arn
#   authorization_security_group_id = dependency.vpc.outputs.docdb_sg_id
# }
