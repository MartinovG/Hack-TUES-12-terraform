// CodePipeline for Frontend
resource "aws_codepipeline" "codepipeline_frontend" {
  for_each      = var.frontend
  name          = "${each.key}-ecs"
  pipeline_type = "V2"
  role_arn      = aws_iam_role.codepipeline_service_role.arn
  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket_ecs.bucket
    type     = "S3"
  }
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      run_order        = "1"
      region           = var.region
      namespace        = "SourceVariables"
      output_artifacts = ["SourceArtifact"]
      configuration = {
        ConnectionArn    = var.github_connection_arn
        FullRepositoryId = each.value.repo_short
        BranchName       = each.value.branch
      }
    }
  }
  stage {
    name = "Build"
    dynamic "action" {
      for_each = var.manual_approval ? [1] : []
      content {
        name      = "Build-Approve"
        category  = "Approval"
        owner     = "AWS"
        provider  = "Manual"
        version   = "1"
        run_order = "1"
        region    = var.region
      }
    }
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      version          = "1"
      run_order        = "2"
      region           = var.region
      namespace        = "BuildVariables"
      configuration = {
        ProjectName = "${each.key}-ecs"
      }
    }
  }
  stage {
    name = "Deploy"
    action {
      name            = "DeployToPublic"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["BuildArtifact"]
      version         = "1"
      run_order       = "1"
      region          = var.region
      namespace       = "DeployVariablesPublic"
      configuration = {
        ClusterName = "${var.environment}-${var.app_name}-cluster"
        ServiceName = "${var.environment}-${var.app_name}-${each.key}-service-public"
      }
    }
  }
  depends_on = [
    aws_iam_role.codepipeline_service_role,
    aws_iam_policy.codepipeline_service_role_policy,
    aws_iam_role_policy_attachment.codepipeline_service_role_policy_attachment,
    aws_codebuild_project.codebuild_frontend
  ]
}
