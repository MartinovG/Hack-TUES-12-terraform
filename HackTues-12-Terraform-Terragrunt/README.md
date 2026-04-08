# RouteOptimizer Infrastructure - Terraform provisioned, Terragrunt managed

IMPORTANT: This repository is managed by Terragrunt.
`root_sentinel.tf` file is used to fail any attempt to run `terraform apply/plan` command from the root of the repo.

## Overview

This repository contains **Terraform modules** managed by **Terragrunt** to provision a secure, highly available AWS infrastructure for the RouteOptimizer application. 

**Three-Tier Architecture**

- Web Tier: ALB + Frontend services in public subnets (minimal surface). Consider CloudFront + WAF in the future.
- App Tier: ECS services in private subnets using ALB target groups.
- Data Tier: DocumentDB isolated with its own SG permitting ingress only from App (ECS) SG and Bastion/VPN SG


## Repository Layout
```
modules/          # Reusable Terraform modules
  common/         # Shared module for account_id, region, GitHub connection
  vpc/            # VPC, subnets, NAT gateways, security groups, flow logs
  acm/            # ACM certificates for ALB
  bastion/        # Bastion host for secure access
  documentDB/     # DocumentDB cluster and instances
  ecr/            # ECR repositories for container images
  ecs/            # ECS cluster, services, task definitions, ALB
  cicd-ecs/       # CodePipeline and CodeBuild for CI/CD
  monitoring/     # CloudWatch alarms and dashboards
  waf/            # WAFv2 Web ACL for ALB protection
live/             # Environment-specific Terragrunt configurations
  dev/
    root.hcl      # Root configuration for dev (shared settings, provider, remote_state, common variables)
    common/terragrunt.hcl
    vpc/terragrunt.hcl
    acm/terragrunt.hcl
    bastion/terragrunt.hcl
    documentDB/terragrunt.hcl
    ecr/terragrunt.hcl
    ecs/terragrunt.hcl
    cicd-ecs/terragrunt.hcl
    monitoring/terragrunt.hcl
    waf/terragrunt.hcl
  stage/          # (Similar structure for staging environment)
  prod/           # (Similar structure for production environment)

README.md         # This document
```
The root configuration file (`root.hcl`) in each environment directory contains shared settings like AWS provider configuration, region, environment name, and service definitions that are inherited by all child modules.

## Remote State Convention

Each environment stores state in an S3 bucket per the convention:
```
Bucket: tfstate-terragrunt-<app_name>-<AWS-account-ID>-<environment>
Key: <module>/terraform.tfstate
```
Terragrunt automatically sets `key = "<module>/terraform.tfstate"` per module.

## State Locking

This configuration uses S3's native file-based locking (`use_lockfile = true`) instead of DynamoDB. When enabled, Terraform creates a `.tflock` file in S3 alongside the state file. S3 provides strong read-after-write consistency and object versioning, which eliminates the need for an external DynamoDB lock table while reducing costs and complexity.


## PRE-DEPLOYMENT INSTRUCTIONS

- Install and configure GIT.
- `git clone` the "terraform" repo 
- Install and configure AWS CLI 2. Mind the different profiles for the different AWS accounts. If IAM Identity Center (SSO) is used, follow these intructions for AWS CLI configuration: https://docs.aws.amazon.com/cli/latest/userguide/sso-configure-profile-token.html#sso-configure-profile-token-auto-sso. In a nut shell start with this:

```shell
$ aws configure sso
SSO session name (Recommended): ganchevs
SSO start URL [None]: https://ganchevs.awsapps.com/start/
SSO region [None]: us-east-1
SSO registration scopes [sso:account:access]: 
CLI default client Region [None]: us-east-1
CLI default output format [None]: json
CLI profile name []: ro-dev
```
**Give appropriate name to the AWS profile, e.g.: "ro-dev"**

Once the session expires, you need to login again (https://docs.aws.amazon.com/cli/latest/userguide/sso-using-profile.html):

```shell
$ aws sso login --profile ro-dev
```

- Install terraform https://www.terraform.io/downloads. Depending on what OS you are using you need to export the environment variable with the AWS profile created in the above step similar to this:

For Linux
```shell
$ export AWS_PROFILE=ro-dev
```

For Windows
```shell
$env:AWS_PROFILE = "ro-dev"
```

**Makes sure you are using LF locally instead of CRLF**
```shell
git config core.eol lf
git config core.autocrlf input
git config --global core.eol lf
git config --global core.autocrlf input
```


## Deployment Instructions

### 1. Prerequisites
- AWS CLI v2 configured (SSO or static credentials).
- Terragrunt v0.93 installed (https://terragrunt.gruntwork.io/docs/getting-started/install/).
- Terraform >= 1.5 installed.
- CodeStar Connection ARN must exist & be authorized for each GitHub repo.
- Secrets Manager key `VITE_GOOGLE_API_KEY` present (referenced downstream by app containers; not created here).
- Route53 hosted zone already provisioned for domain used in frontend API URL.
- AWS SSO session active or credentials exported.

### 2. Terragrunt Commands

```bash
# Work with a single module
cd live/dev/vpc
terragrunt init --backend-bootstrap
terragrunt validate
terragrunt plan
terragrunt apply

# Work with all modules in an environment (leverages dependency graph)
cd live/dev
terragrunt run --all init --backend-bootstrap
terragrunt run --all validate
terragrunt run --all plan
terragrunt run --all apply --non-interactive

# Target specific modules with dependencies
cd live/dev/ecs
terragrunt apply  # Automatically applies ecs and all its dependencies
```

**Key Points**:
- Dependencies are automatically resolved via `dependency` blocks in each module's `terragrunt.hcl`
- `terragrunt run --all <command>` respects the dependency graph (DAG) and executes in correct order all modules
- Terragrunt automatically handles dependencies when running a single module

### 3. Bootstrap Remote State

Terragrunt can automatically provision the S3 bucket for remote state using either a dedicated command or a flag.

The `backend bootstrap` command explicitly provisions backend resources defined in the `remote_state` block.

**Important:** Since the AWS provider profile is configured in the generated `provider.tf`, you must set the `AWS_PROFILE` environment variable for backend operations:

```bash
# Bootstrap backend for a single module
cd live/dev/vpc
AWS_PROFILE=ro-dev terragrunt init --backend-bootstrap

# Bootstrap for all modules in an environment (will prompt for confirmation)
cd live/dev
AWS_PROFILE=ro-dev terragrunt run --all init --backend-bootstrap
```

This will create:
- S3 bucket with the configured name
- Enable versioning on the bucket (for state history and locking)
- Enable encryption


### 4. Manage infra

**Destroy a module**:
```bash
cd live/dev/vpc
terragrunt destroy
```

**Destroy entire environment**:
```bash
cd live/dev
terragrunt run --all destroy --non-interactive
```

**View Infrastructure State**:
```bash
# Get outputs from a single module
cd live/dev/vpc
terragrunt output
```

**Troubleshooting**:
```bash
# Re-initialize a module (e.g., after provider updates)
cd live/dev/vpc
terragrunt init -upgrade

# Check dependency graph
cd live/dev
terragrunt graph-dependencies | dot -Tpng > deps.png
```

**Backend Management Commands**:
Terragrunt v0.93+ provides dedicated backend commands:
- `terragrunt init --backend-bootstrap` - Create/provision backend resources
- `terragrunt backend migrate` - Migrate state between backends
- `terragrunt backend delete` - Delete backend state files



## Implemented Security & HA Enhancements

### 1. WAF Module (`modules/waf`)
Comprehensive AWS WAFv2 Web ACL protecting the ALB with:
- **AWS Managed Rules**: Core Rule Set (OWASP Top 10), Known Bad Inputs, SQL Injection protection
- **Rate Limiting**: 2000 requests per 5 minutes per IP address
- **Geo-Blocking**: Optional country-level blocking (configurable via `blocked_countries` variable)
- **Logging**: CloudWatch Logs integration with sensitive header redaction
- **Metrics**: Full CloudWatch metrics for monitoring blocked/allowed requests

### 2. Monitoring Module (`modules/monitoring`)
CloudWatch-based comprehensive monitoring with SNS alerting:
- **ECS Alarms**: CPU/Memory utilization thresholds (80%) per service
- **ALB Alarms**: Unhealthy targets, 5XX error counts, high request count
- **DocumentDB Alarms**: CPU utilization, connection counts, free storage space
- **NAT Gateway Alarms**: Port allocation errors
- **CloudWatch Dashboard**: Unified view of all infrastructure metrics
- **SNS Email Notifications**: Configure email recipients via `alarm_emails` variable

The request count alarm triggers when total requests exceed the configurable threshold per 5-minute period. Adjust via `request_count_threshold` variable.

### 3. VPC Flow Logs
Implemented in VPC module:
- Flow logs capturing ALL traffic (ACCEPT/REJECT)
- CloudWatch Logs destination with 7-day retention
- Dedicated IAM role for VPC Flow Logs service


## Future improvements:

1. Add a WAFv2 WebACL and CloudFront for Layer 7 protection and low latency
2. Introduce PrivateLink or VPC Endpoints for S3, ECR, Logs to remove NAT dependency and reduce egress.
3. Add an AWS Network Firewall or NACL hardening for egress control on private subnets.
4. Implement IAM least-privilege for task roles (currently broad due to app development phase; refine policies per service).
5. Enable encryption: ECS Fargate ephemeral storage encryption; KMS CMK for DocumentDB; TLS for DocumentDB
6. High Availability: Increase DocumentDB instances (writer + at least 2 replicas across AZs) and scale ECS services with health checks.
7. Improved security: Automated DocumentDB password rotation using AWS Secrets Manager.
8. DevOps optimization: Add integration tests (Terratest) validating module outputs and security group rules.
9. Further security enhancements: **AWS Config**: Enable compliance checking (encrypted volumes, public access). **GuardDuty**: Enable threat detection for VPC, S3, ECS. **Security Hub**: Aggregate findings from GuardDuty, Config, IAM Access Analyzer









