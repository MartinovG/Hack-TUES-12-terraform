// CodeBuild for Frontend
resource "aws_codebuild_project" "codebuild_frontend" {
  for_each       = var.frontend
  name           = local.codebuild_frontend_project_names[each.key]
  description    = "CodeBuild to build the frontend image and push it to ECR for use by ECS"
  service_role   = aws_iam_role.codebuild_service_role.arn
  source_version = each.value.branch
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
    environment_variable {
      name  = "VITE_API_URL"
      value = "https://${var.environment}.${var.app_name}.${var.main_domain}"
    }
  }
  source {
    type            = "GITHUB"
    location        = each.value.repo_long
    git_clone_depth = 0
    git_submodules_config {
      fetch_submodules = true
    }
    buildspec = templatefile("${path.module}/buildspec-frontend.yml", {
      AWS_DEFAULT_REGION                          = var.region
      AWS_ACCOUNT_ID                              = var.account_id
      IMAGE_REPO_NAME                             = "${var.environment}-${var.app_name}-${each.key}-repo"
      CONTAINER_NAME                              = "${var.environment}-${var.app_name}-${each.key}"
      TASK_DEFINITION_ARN_FAMILY_WITHOUT_REVISION = var.frontend_task_arn_without_revision[each.key]
      CONTAINER_PORT                              = each.value.port
      TASK_DEFINITION_FAMILY                      = "${var.environment}-${var.app_name}-${each.key}"
      SECURITY_GROUP                              = var.ecs_sg_id
      SUBNETS_PRIVATE_A                           = var.private_subnet_a_id
      SUBNETS_PRIVATE_B                           = var.private_subnet_b_id
      SUBNETS_PRIVATE_C                           = var.private_subnet_c_id
    })
  }
  cache {
    type = "NO_CACHE"
  }
  build_timeout  = "60"
  queued_timeout = "480"
  badge_enabled  = true
  vpc_config {
    security_group_ids = [var.codebuild_sg_id]
    subnets            = var.codebuild_private_subnet_ids
    vpc_id             = var.vpc_id
  }
  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild_frontend_logging.name
      status     = "ENABLED"
    }
  }
}
resource "aws_cloudwatch_log_group" "codebuild_frontend_logging" {
  name              = local.codebuild_frontend_log_group_name
  retention_in_days = 7
}
