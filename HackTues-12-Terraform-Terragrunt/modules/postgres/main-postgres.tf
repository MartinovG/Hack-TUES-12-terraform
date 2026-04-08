resource "random_password" "postgres_password" {
  length  = 24
  special = false
}

locals {
  postgres_db_name    = replace(var.app_name, "-", "_")
  postgres_username   = "hacktues12"
  first_three_private = slice(var.private_subnet_ids, 0, min(length(var.private_subnet_ids), 3))
}

resource "aws_db_subnet_group" "postgres" {
  name       = "${var.environment}-${var.app_name}-postgres-private"
  subnet_ids = local.first_three_private

  tags = {
    Name = "${var.environment}-${var.app_name}-postgres-private"
  }
}

resource "aws_ssm_parameter" "postgres_username" {
  name  = "/Postgres/${var.environment}/${var.app_name}/username"
  type  = "String"
  value = local.postgres_username
}

resource "aws_ssm_parameter" "postgres_password" {
  name  = "/Postgres/${var.environment}/${var.app_name}/password"
  type  = "SecureString"
  value = random_password.postgres_password.result
}

resource "aws_ssm_parameter" "postgres_database_name" {
  name  = "/Postgres/${var.environment}/${var.app_name}/database"
  type  = "String"
  value = local.postgres_db_name
}

resource "aws_db_instance" "postgres" {
  identifier                = "${var.environment}-${var.app_name}-postgres"
  allocated_storage         = 20
  engine                    = "postgres"
  engine_version            = "17.4"
  instance_class            = "db.t4g.micro"
  db_subnet_group_name      = aws_db_subnet_group.postgres.name
  vpc_security_group_ids    = [var.postgres_sg_id]
  username                  = aws_ssm_parameter.postgres_username.value
  password                  = aws_ssm_parameter.postgres_password.value
  db_name                   = aws_ssm_parameter.postgres_database_name.value
  port                      = 5432
  multi_az                  = false
  publicly_accessible       = false
  storage_encrypted         = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.environment}-${var.app_name}-postgres-final-snapshot"
  deletion_protection       = false
  backup_retention_period   = 7
  apply_immediately         = true
}

resource "aws_sns_topic" "postgres" {
  name = "${var.environment}-${var.app_name}-postgres-topic"
}

resource "aws_sns_topic_subscription" "postgres" {
  for_each  = toset(var.notification_emails)
  topic_arn = aws_sns_topic.postgres.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_db_event_subscription" "postgres" {
  name             = "${var.environment}-${var.app_name}-postgres-event"
  sns_topic        = aws_sns_topic.postgres.arn
  source_type      = "db-instance"
  source_ids       = [aws_db_instance.postgres.identifier]
  event_categories = ["availability", "backup", "configuration change", "deletion", "failure", "maintenance", "notification", "recovery"]

  depends_on = [aws_db_instance.postgres]
}
