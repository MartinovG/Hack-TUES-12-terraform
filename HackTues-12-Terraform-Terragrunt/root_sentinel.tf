// Sentinel to prevent using Terraform at the repository root.
// This repo is managed with Terragrunt under the live/ directory.

terraform {
  required_version = ">= 1.5.0"
}

variable "DO_NOT_RUN_TERRAFORM_IN_REPO_ROOT" {
  description = "This repo uses Terragrunt. Run from live/{dev,stage,prod} with terragrunt."
  type        = bool
  default     = false

  validation {
    condition     = var.DO_NOT_RUN_TERRAFORM_IN_REPO_ROOT
    error_message = "Do not run Terraform at the repo root. Use: cd live/<env> && terragrunt run-all <cmd>."
  }
}
