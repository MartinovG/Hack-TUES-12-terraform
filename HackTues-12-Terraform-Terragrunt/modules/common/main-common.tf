# This module provides common data sources that can be reused across environments.
# Purpose: Centralize dynamic resource lookups to avoid hardcoding values.

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Fetch CodeStar connection only when CI/CD is enabled in the environment.
data "aws_codestarconnections_connection" "github" {
  count = var.github_connection_name != "" ? 1 : 0
  name  = var.github_connection_name
}
