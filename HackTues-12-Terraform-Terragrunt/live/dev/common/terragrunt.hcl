terraform {
  source = "../../../modules/common"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  parent_locals = read_terragrunt_config(find_in_parent_folders("root.hcl"))
}

# This module fetches common data sources dynamically
# No dependencies needed - it only reads existing AWS resources
inputs = {
  github_connection_name = local.parent_locals.locals.github_connection_name
}
