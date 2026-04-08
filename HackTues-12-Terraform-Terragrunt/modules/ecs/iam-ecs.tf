

////////////////////////////////////// IAM roles and policies //////////////////////////////////////////

///////////////// Task role and policies

resource "aws_iam_role" "ecs_task_role" {
  name                 = "${var.environment}-${var.app_name}-TaskDefinition-TaskRole"
  description          = "Allows ECS tasks to call AWS services on your behalf"
  max_session_duration = 43200 // 12 hours

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": "",
     "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "${var.account_id}"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:ecs:${var.region}:${var.account_id}:*"
        }
      }
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy_attachment_task_role_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.task_role_policy.arn
}
resource "aws_iam_policy" "task_role_policy" {
  name   = "TaskPermissions"
  path   = "/"
  policy = data.aws_iam_policy_document.task_role_policy_template.json
}
data "aws_iam_policy_document" "task_role_policy_template" {
  statement {
    sid    = "TaskPermissions"
    effect = "Allow"
    actions = [
      "ecs:*",
      "ssmmessages:*",
      "logs:*",
      "rds:*",
      "route53:*",
      "route53domains:*",
      "route53resolver:*",
      "s3:*",
      "s3-object-lambda:*",
      "sns:*",
      "pipes:*",
      "cloudwatch:*",
      "ec2:*",
      "ssm:*",
      "secretsmanager:*",
      "kms:*",
      "application-autoscaling:*",
      "iam:*"
    ]
    resources = ["*"]
  }
}



///////////////////////////// Task Execution Role

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRol-${var.app_name}"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment_ecs_accessing_secrets" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_accessing_secrets.arn
}



/// Policy for the secrets

resource "aws_iam_policy" "ecs_accessing_secrets" {
  name        = "ecs_accessing_secrets"
  description = "Policy allowing ECS to access both Parameter Store secrets and Secrets Manager secrets"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["secretsmanager:GetSecretValue", "ssm:GetParameters"],
      "Effect": "Allow",
      "Resource": "*",
      "Sid": "AccessToSecrets"
    }
  ]
}
EOF
}