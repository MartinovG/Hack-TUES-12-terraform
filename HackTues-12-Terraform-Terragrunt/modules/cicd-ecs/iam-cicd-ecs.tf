// IAM Assume Role Policy Documents
data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "codepipeline_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

// CodeBuild Service Role Policy Document
data "aws_iam_policy_document" "codebuild_service_role" {
  # Allow creating log groups in this account/region
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:${var.region}:${var.account_id}:*"]
  }

  # Stream and put events only to our CodeBuild log groups
  statement {
    effect  = "Allow"
    actions = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = [
      "arn:aws:logs:${var.region}:${var.account_id}:log-group:${local.codebuild_core_app_log_group_name}:*",
      "arn:aws:logs:${var.region}:${var.account_id}:log-group:${local.codebuild_frontend_log_group_name}:*",
      "arn:aws:logs:${var.region}:${var.account_id}:log-group:${local.codebuild_service_log_group_name}:*"
    ]
  }

  # ECR auth token requires * resource
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # VPC configuration requires EC2 permissions
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeVpcs",
      "ec2:CreateNetworkInterfacePermission"
    ]
    resources = ["*"]
  }

  # Limit ECR data-plane to our repos
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
    ]
    resources = [
      "arn:aws:ecr:${var.region}:${var.account_id}:repository/${var.environment}-${var.app_name}-backend-repo",
      "arn:aws:ecr:${var.region}:${var.account_id}:repository/${var.environment}-${var.app_name}-frontend-repo",
      "arn:aws:ecr:${var.region}:${var.account_id}:repository/${var.environment}-${var.app_name}-algorithms-repo"
    ]
  }

  # Restrict ECS reads to task definitions in this account
  statement {
    effect    = "Allow"
    actions   = ["ecs:DescribeTaskDefinition"]
    resources = ["arn:aws:ecs:${var.region}:${var.account_id}:task-definition/${var.environment}-${var.app_name}-*"]
  }

  # S3 access to the artifact bucket for CodePipeline integration
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]
    resources = ["arn:aws:s3:::${var.environment}-${var.app_name}-codepipeline-artefacts-ecs/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:ListAllMyBuckets"]
    resources = ["arn:aws:s3:::${var.environment}-${var.app_name}-codepipeline-artefacts-ecs"]
  }

  # CodeBuild test reporting
  statement {
    effect = "Allow"
    actions = [
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases",
      "codebuild:BatchPutCodeCoverages"
    ]
    resources = ["arn:aws:codebuild:${var.region}:${var.account_id}:report-group/*"]
  }

  # Secrets Manager and SSM Parameter Store access
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters", "ssm:GetParameter", "secretsmanager:GetSecretValue"]
    resources = ["*"]
  }

  # CloudFront and ACM permissions for invalidations and certificate management
  statement {
    effect = "Allow"
    actions = [
      "acm:ListCertificates",
      "cloudfront:GetDistribution",
      "cloudfront:GetStreamingDistribution",
      "cloudfront:GetDistributionConfig",
      "cloudfront:ListDistributions",
      "cloudfront:ListCloudFrontOriginAccessIdentities",
      "cloudfront:CreateInvalidation",
      "cloudfront:GetInvalidation",
      "cloudfront:ListInvalidations",
      "elasticloadbalancing:DescribeLoadBalancers",
      "iam:ListServerCertificates",
      "sns:ListSubscriptionsByTopic",
      "sns:ListTopics",
      "waf:GetWebACL",
      "waf:ListWebACLs"
    ]
    resources = ["*"]
  }

  # Deny OAuth token deletion
  statement {
    effect    = "Deny"
    actions   = ["codebuild:DeleteOAuthToken"]
    resources = ["*"]
  }
}

// CodePipeline Service Role Policy Document
data "aws_iam_policy_document" "codepipeline_service_role" {
  # CodePipeline needs broad permissions on its own API
  statement {
    effect    = "Allow"
    actions   = ["codepipeline:*"]
    resources = ["*"]
  }

  # Restrict CodeStar connection usage to provided ARN
  statement {
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection"]
    resources = [var.github_connection_arn]
  }

  # Restrict S3 access to the artifact bucket
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.environment}-${var.app_name}-codepipeline-artefacts-ecs"]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"]
    resources = ["arn:aws:s3:::${var.environment}-${var.app_name}-codepipeline-artefacts-ecs/*"]
  }

  # Allow CodeBuild project interactions
  statement {
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    resources = concat(
      [for project_name in values(local.codebuild_core_app_project_names) : "arn:aws:codebuild:${var.region}:${var.account_id}:project/${project_name}"],
      [for project_name in values(local.codebuild_frontend_project_names) : "arn:aws:codebuild:${var.region}:${var.account_id}:project/${project_name}"],
      [for project_name in values(local.codebuild_service_project_names) : "arn:aws:codebuild:${var.region}:${var.account_id}:project/${project_name}"]
    )
  }

  # ECR image description
  statement {
    effect    = "Allow"
    actions   = ["ecr:DescribeImages"]
    resources = ["*"]
  }

  # Allow ECS deployments - comprehensive permissions for CodePipeline ECS deploy action
  statement {
    effect = "Allow"
    actions = [
      "ecs:*",
      "elasticloadbalancing:*",
      "autoscaling:*"
    ]
    resources = ["*"]
  }

  # SNS notifications
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = ["*"]
  }

  # Lambda invocations for pipeline actions
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeAsync",
      "lambda:InvokeFunction",
      "lambda:ListFunctions"
    ]
    resources = ["*"]
  }

  # Allow getting role information for ECS task roles
  statement {
    effect    = "Allow"
    actions   = ["iam:GetRole"]
    resources = ["arn:aws:iam::${var.account_id}:role/${var.environment}-${var.app_name}-*"]
  }

  # Constrain PassRole to ECS tasks only within this account
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${var.account_id}:role/*"]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

// IAM resources for CICD
resource "aws_iam_role" "codebuild_service_role" {
  name               = "${var.environment}-${var.app_name}-codebuild--service-role"
  path               = "/service-role/"
  description        = "CodeBuild Service role for ECS"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

resource "aws_iam_policy" "codebuild_service_role_policy" {
  name        = "${var.environment}-${var.app_name}-CodeBuildServiceRolePolicy"
  path        = "/service-role/"
  description = "Policy used in trust relationship with CodeBuild"
  policy      = data.aws_iam_policy_document.codebuild_service_role.json
}

resource "aws_iam_role_policy_attachment" "codebuild_service_role_policy_attachment" {
  role       = aws_iam_role.codebuild_service_role.name
  policy_arn = aws_iam_policy.codebuild_service_role_policy.arn
}

# ECR managed policy for additional ECR permissions
resource "aws_iam_role_policy_attachment" "codebuild_service_role_ecr_policy_attachment" {
  role       = aws_iam_role.codebuild_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

// Removed broad ECR managed policy; inline policy provides least-privilege ECR access
resource "aws_iam_role" "codepipeline_service_role" {
  name               = "${var.environment}-${var.app_name}-codepipeline-service-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json
}

resource "aws_iam_policy" "codepipeline_service_role_policy" {
  name   = "${var.environment}-${var.app_name}-CodePipelineServiceRolePolicy"
  path   = "/service-role/"
  policy = data.aws_iam_policy_document.codepipeline_service_role.json
}

resource "aws_iam_role_policy_attachment" "codepipeline_service_role_policy_attachment" {
  role       = aws_iam_role.codepipeline_service_role.name
  policy_arn = aws_iam_policy.codepipeline_service_role_policy.arn
}
