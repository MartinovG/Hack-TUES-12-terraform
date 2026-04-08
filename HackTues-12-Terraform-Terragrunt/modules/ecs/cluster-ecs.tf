//////////////////////////////////////////// Cluster ////////////////////////////////////////////

resource "aws_ecs_cluster" "main_cluster" {
  name = "${var.environment}-${var.app_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = false
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.main_cluster_logging.name
      }
    }
  }
}


// Cluster logging - Backend
resource "aws_cloudwatch_log_group" "main_cluster_logging" {
  name              = "/ecs/${var.environment}-${var.app_name}"
  retention_in_days = 7 //set to 0 to never expire
}
