locals {
  environment        = "dev"
  app_name           = "hack-tues-12"
  account_id_default = "536697243063"
  region_default     = "us-east-1"

  # Compute region and account_id dynamically to avoid hardcoding in root.hcl.
  # Both are required here only for provider config and remote_state bucket naming.
  aws_profile = "ro-dev"
  region      = get_env("TG_AWS_REGION", local.region_default)
  account_id  = get_env("TG_AWS_ACCOUNT_ID", local.account_id_default)

  main_domain = "innovatebulgaria.com"

  # Notification recipients (used by modules like documentDB)
  notification_emails = [
    "krassimir.ganchev@gmail.com"
  ]

  # CodeStar connection for GitHub (used by CICD pipelines)
  github_connection_name = ""

  # VPC addressing (used by VPC module)
  vpc_cidr                       = "10.64.0.0/16"
  public_subnets_cidr            = ["10.64.0.0/24", "10.64.1.0/24", "10.64.2.0/24"]
  private_subnets_cidr           = ["10.64.3.0/24", "10.64.4.0/24", "10.64.5.0/24"]
  codebuild_private_subnets_cidr = ["10.64.6.0/24", "10.64.7.0/24", "10.64.8.0/24"]
  availability_zones             = ["a", "b", "c"]

  # Bastion configuration
  bastion_instance_type = "t2.micro"

  # Service configurations
  service = {}

  core_app = {
    "backend" = {
      repo_long     = "https://github.com/MartinovG/Hack-TUES-12-backend.git"
      repo_short    = "MartinovG/Hack-TUES-12-backend"
      branch        = "develop"
      port          = 8000
      external_port = 8000
    }
  }

  frontend = {
    "frontend" = {
      repo_long           = "https://github.com/MartinovG/Hack-TUES-12-frontend.git"
      repo_short          = "MartinovG/Hack-TUES-12-frontend"
      branch              = "dev"
      port                = 5173
      external_http_port  = 80
      external_https_port = 443
    }
  }
}

# Generate provider.tf with AWS provider configuration including default tags
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.18"
    }
  }
}

provider "aws" {
  region  = "${local.region}"
  profile = "${local.aws_profile}"
  
  default_tags {
    tags = {
      Environment = upper("${local.environment}")
      Owner       = "DevOps"
      Managed_by  = "terraform"
      App         = upper("${local.app_name}")
    }
  }
}
EOF
}

remote_state {
  backend = "s3"
  config = {
    bucket       = "tfstate-terragrunt-${local.app_name}-${local.account_id}-${local.environment}"
    key          = "${path_relative_to_include()}/terraform.tfstate"
    region       = local.region
    encrypt      = true
    use_lockfile = true
    # Using S3 native locking with .tflock file instead of DynamoDB
    # S3 uses object versioning and consistency guarantees for state locking
  }
}

inputs = {
  environment = local.environment
  app_name    = local.app_name
  service     = local.service
  core_app    = local.core_app
  frontend    = local.frontend
  # NOTE: region and account_id are NOT passed from root.hcl
  # Instead, child modules receive them from the 'common' module dependency
}
