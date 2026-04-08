//////////////////////////////////////////// Backend container //////////////////////////////////////


// Task definition
resource "aws_ecs_task_definition" "core_app_task" {
  for_each = var.core_app

  cpu                      = 1024
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  family                   = "${var.environment}-${var.app_name}-${each.key}"
  memory                   = 2048
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  skip_destroy             = false //Whether to retain the old revision when the resource is destroyed or replacement is necessary. Default is false.
  runtime_platform {
    operating_system_family = "LINUX"
  }
  task_role_arn = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode(
    [
      {
        name      = "${var.environment}-${var.app_name}-${each.key}"
        image     = "${var.core_app_ecr_url[each.key]}:${lookup(var.core_app_image_tag, each.key, "latest")}"
        essential = true
        environment = [
          {
            name  = "PORT"
            value = tostring(each.value.port)
          },
          {
            name  = "API_HOST"
            value = "https://${var.environment}.${var.app_name}.${var.main_domain}"
          },
          {
            name  = "JWT_SECRET"
            value = "your_jwt_secret_key"
          },
          {
            name  = "DATABASE_URL"
            value = var.database_url
          },
          {
            name  = "DB_SSL"
            value = "true"
          },
          {
            name  = "DB_SYNCHRONIZE"
            value = "true"
          },
          {
            name  = "NODE_TLS_REJECT_UNAUTHORIZED"
            value = "0"
          },
          {
            name  = "CORS_ORIGIN"
            value = "https://${var.environment}.${var.app_name}.${var.main_domain}"
          }
        ]
        secrets = [
          {
            name      = "GOOGLE_API_KEY"
            valueFrom = data.aws_secretsmanager_secret_version.VITE_GOOGLE_API_KEY.arn
          }
        ]
        portMappings = [{
          protocol      = "tcp"
          containerPort = each.value.port
          hostPort      = each.value.port
        }]
        # healthCheck = {
        #   command     = ["CMD-SHELL", "curl -f http://localhost/health || exit 1"]
        #   interval    = 30
        #   timeout     = 5
        #   retries     = 3
        #   startPeriod = 10
        # }
        command    = []
        cpu        = 0
        entryPoint = []
        links      = []
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.main_cluster_logging.name
            awslogs-region        = var.region
            awslogs-stream-prefix = "ecs"
          }
        }
        mountPoints = []
        volumesFrom = []
      }
    ]
  )
}


////////////////////////////////////////////////////////////////////// for Public ALB //////////////////////////////////////////////

// Service for the Core app container behind Public ALB

resource "aws_ecs_service" "core_app_service_public" {
  for_each = var.core_app

  name                               = "${var.environment}-${var.app_name}-${each.key}-service-public"
  cluster                            = aws_ecs_cluster.main_cluster.id
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = 1
  enable_ecs_managed_tags            = true
  enable_execute_command             = true
  force_new_deployment               = true // update tasks to use a newer Docker image with same image/tag combination (e.g., myimage:latest), roll Fargate tasks onto a newer platform version, or immediately deploy ordered_placement_strategy and placement_constraints updates.
  health_check_grace_period_seconds  = 900
  launch_type                        = "FARGATE"

  # Public ALB
  load_balancer {
    container_name   = "${var.environment}-${var.app_name}-${each.key}"
    container_port   = each.value.port
    target_group_arn = aws_lb_target_group.public_alb_core_app_target_group[each.key].arn // Used by the Green/Blue CodeDeploy
  }

  network_configuration {
    assign_public_ip = false
    security_groups = [
      var.ecs_sg_id
    ]
    subnets = var.private_subnet_ids
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker { // Works only with ECS deployment_controller, https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_DeploymentCircuitBreaker.html , https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-type-ecs.html 
    enable   = true
    rollback = true
  }
  platform_version = "LATEST" // Cannot be used with CodeDeply

  scheduling_strategy   = "REPLICA"
  task_definition       = aws_ecs_task_definition.core_app_task[each.key].arn
  wait_for_steady_state = false // If "true", Terraform will wait for the service to reach a steady state (like aws ecs wait services-stable) before continuing. Default is false.

  lifecycle {
    ignore_changes = [
      desired_count, // The desired number of tasks needs to be ignored because I also attached autoscaling rules to the service which allow the service to down- or upscale the number of tasks based on the load.
      load_balancer  // Comment it when changing the name of the target group
    ]
  }

  depends_on = [aws_lb_listener.public_alb_listener_core_app]
}


///////////////////////////////////////// Task Autoscaling for the Core-app container ////////////////////////////



// Task Autoscaling. In case of problems, Consider it carefully in case of Blue/Green deployment with CodeBuild
// https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-type-bluegreen.html 


resource "aws_appautoscaling_target" "ecs_core_app_target_public" {
  for_each = var.core_app

  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main_cluster.name}/${aws_ecs_service.core_app_service_public[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_core_app_policy_memory_public" {
  for_each = var.core_app

  name               = "memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_core_app_target_public[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_core_app_target_public[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_core_app_target_public[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 80
  }
}

resource "aws_appautoscaling_policy" "ecs_core_app_policy_cpu_public" {
  for_each = var.core_app

  name               = "cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_core_app_target_public[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_core_app_target_public[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_core_app_target_public[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 80
  }
}

resource "aws_appautoscaling_policy" "ecs_core_app_policy_alb_load_public" {
  for_each = var.core_app

  name               = "alb-load-autoscaling-${each.key}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_core_app_target_public[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_core_app_target_public[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_core_app_target_public[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      # The next reasource_label has to be specified every time for every environment. 
      # You create the resource label by appending the final portion of the load balancer ARN and the final portion of the target group ARN into a single value, separated by a forward slash (/).
      resource_label = "${aws_lb.public_alb.arn_suffix}/${aws_lb_target_group.public_alb_core_app_target_group[each.key].arn_suffix}" // Used by the Green/Blue CodeDeploy
    }

    target_value = 1000 // This has to be set correctly based on real life statistics
  }

  lifecycle {
    ignore_changes = [
      target_tracking_scaling_policy_configuration
    ]
  }
}
