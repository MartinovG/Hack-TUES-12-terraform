# SNS Topic for CloudWatch Alarms
resource "aws_sns_topic" "alarms" {
  name              = "${var.app_name}-${var.environment}-alarms"
  display_name      = "CloudWatch Alarms for ${var.app_name} ${var.environment}"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name = "${var.app_name}-${var.environment}-alarms"
  }
}

# SNS Topic Subscription (Email)
resource "aws_sns_topic_subscription" "alarms_email" {
  count     = length(var.alarm_emails) > 0 ? length(var.alarm_emails) : 0
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_emails[count.index]
}

# ECS Service CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  for_each = var.ecs_services

  alarm_name          = "${var.app_name}-${var.environment}-${each.key}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS CPU utilization for ${each.key}"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = each.value
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-${each.key}-cpu-high"
  }
}

# ECS Service Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  for_each = var.ecs_services

  alarm_name          = "${var.app_name}-${var.environment}-${each.key}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS memory utilization for ${each.key}"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = each.value
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-${each.key}-memory-high"
  }
}

# ALB Target Health Alarm
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_targets" {
  count = var.alb_target_group_arn != "" ? 1 : 0

  alarm_name          = "${var.app_name}-${var.environment}-alb-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "This metric monitors unhealthy targets in ALB"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    TargetGroup  = split(":", var.alb_target_group_arn)[5]
    LoadBalancer = split("/", split(":", var.alb_target_group_arn)[5])[1]
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-alb-unhealthy-targets"
  }
}

# ALB 5XX Errors Alarm
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  count = var.alb_arn != "" ? 1 : 0

  alarm_name          = "${var.app_name}-${var.environment}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors 5XX errors from ALB targets"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = split("/", var.alb_arn)[1]
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-alb-5xx-errors"
  }
}

# ALB Request Count Alarm
resource "aws_cloudwatch_metric_alarm" "alb_request_count_high" {
  count = var.alb_arn != "" ? 1 : 0

  alarm_name          = "${var.app_name}-${var.environment}-alb-request-count-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "RequestCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.request_count_threshold
  alarm_description   = "This metric monitors total request count to the ALB and triggers when requests exceed ${var.request_count_threshold} in a 5-minute period"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = split("/", var.alb_arn)[1]
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-alb-request-count-high"
  }
}

# PostgreSQL CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "postgres_cpu_high" {
  count = var.postgres_instance_id != "" ? 1 : 0

  alarm_name          = "${var.app_name}-${var.environment}-postgres-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors PostgreSQL CPU utilization"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    DBInstanceIdentifier = var.postgres_instance_id
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-postgres-cpu-high"
  }
}

# PostgreSQL Database Connections Alarm
resource "aws_cloudwatch_metric_alarm" "postgres_connections_high" {
  count = var.postgres_instance_id != "" ? 1 : 0

  alarm_name          = "${var.app_name}-${var.environment}-postgres-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "This metric monitors PostgreSQL database connections"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    DBInstanceIdentifier = var.postgres_instance_id
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-postgres-connections-high"
  }
}

# PostgreSQL Free Storage Space Alarm
resource "aws_cloudwatch_metric_alarm" "postgres_storage_low" {
  count = var.postgres_instance_id != "" ? 1 : 0

  alarm_name          = "${var.app_name}-${var.environment}-postgres-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "5000000000" # 5 GB in bytes
  alarm_description   = "This metric monitors PostgreSQL free storage space"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    DBInstanceIdentifier = var.postgres_instance_id
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-postgres-storage-low"
  }
}

# NAT Gateway ErrorPortAllocation Alarm
resource "aws_cloudwatch_metric_alarm" "nat_gateway_errors" {
  count = length(var.nat_gateway_ids)

  alarm_name          = "${var.app_name}-${var.environment}-nat-gateway-${count.index}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ErrorPortAllocation"
  namespace           = "AWS/NATGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors NAT Gateway port allocation errors"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    NatGatewayId = var.nat_gateway_ids[count.index]
  }

  tags = {
    Name = "${var.app_name}-${var.environment}-nat-gateway-${count.index}-errors"
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.app_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            for key, service in var.ecs_services : [
              "AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", service
            ]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "ECS CPU Utilization"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            for key, service in var.ecs_services : [
              "AWS/ECS", "MemoryUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", service
            ]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "ECS Memory Utilization"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = var.alb_arn != "" ? [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", split("/", var.alb_arn)[1]],
            [".", "RequestCount", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ] : []
          period = 300
          stat   = "Average"
          region = var.region
          title  = "ALB Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = var.postgres_instance_id != "" ? [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.postgres_instance_id],
            [".", "DatabaseConnections", ".", "."],
            [".", "FreeStorageSpace", ".", "."]
          ] : []
          period = 300
          stat   = "Average"
          region = var.region
          title  = "PostgreSQL Metrics"
        }
      }
    ]
  })
}
