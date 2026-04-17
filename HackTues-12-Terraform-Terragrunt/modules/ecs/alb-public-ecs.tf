///////////////////////// Internet-facing Application Load Balancer with target group and listener rules


// ALB 

resource "aws_lb" "public_alb" {
  name               = "${var.environment}-${var.app_name}-public-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids
}

resource "aws_ssm_parameter" "public_alb_DNS" {
  name        = "/lb/${var.environment}/${var.app_name}/public-alb-dns"
  description = "The DNS name of the Public ALB"
  type        = "String"
  value       = aws_lb.public_alb.dns_name
}

// ALB DNS record

resource "aws_route53_record" "public_alb_dns_A_record" {
  zone_id         = var.hosted_zone_id
  name            = "${var.environment}.${var.app_name}.${var.main_domain}"
  type            = "A"
  allow_overwrite = true
  alias {
    name                   = aws_lb.public_alb.dns_name
    zone_id                = aws_lb.public_alb.zone_id
    evaluate_target_health = true
  }
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                               FRONTEND container                                                                               //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



/////////////////// Target groups for the Frontend container

resource "aws_lb_target_group" "public_alb_frontend_target_group" {
  for_each = var.frontend

  # name                  = "PBL-${each.key}"
  name_prefix = "PBL-FE"
  port        = each.value.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "5"
    interval            = "30"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
    timeout             = "5"
    path                = "/health"
    unhealthy_threshold = "2"
  }

  stickiness {
    cookie_duration = 86400
    enabled         = false
    type            = "lb_cookie"
  }

  tags = {
    Name = "PBL-${each.key}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

// ALB listeners
resource "aws_lb_listener" "public_alb_listener_frontend_HTTP" {
  for_each = var.frontend

  load_balancer_arn = aws_lb.public_alb.id
  port              = each.value.external_http_port
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = each.value.external_https_port
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "public_alb_listener_frontend_HTTPS" {
  for_each = var.frontend

  load_balancer_arn = aws_lb.public_alb.id
  port              = each.value.external_https_port
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = var.certificate_arn // provided by Terragrunt dependency

  default_action {
    target_group_arn = aws_lb_target_group.public_alb_frontend_target_group[each.key].arn
    type             = "forward"
  }
}

locals {
  backend_path_groups = {
    backend-auth = {
      priority = 100
      service  = "backend"
      values   = ["/backend", "/backend/*", "/auth", "/auth/*", "/health"]
    }
    backend-users = {
      priority = 101
      service  = "backend"
      values   = ["/users", "/users/*", "/vms", "/vms/*", "/rentals"]
    }
    backend-rentals = {
      priority = 102
      service  = "backend"
      values   = ["/rentals/*", "/jobs", "/jobs/*", "/metrics", "/metrics/*"]
    }
    backend-tools = {
      priority = 103
      service  = "backend"
      values   = ["/calculator", "/calculator/*", "/computers", "/computers/*", "/download*"]
    }
    backend-socket = {
      priority = 104
      service  = "backend"
      values   = ["/computer-socket", "/computer-socket/*"]
    }
  }
}

// Path-based routing
resource "aws_lb_listener_rule" "public_alb_listener_frontend_HTTPS_path" {
  for_each = local.backend_path_groups

  listener_arn = aws_lb_listener.public_alb_listener_frontend_HTTPS["frontend"].arn

  priority = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_alb_core_app_target_group[each.value.service].arn
  }

  condition {
    path_pattern {
      values = each.value.values
    }
  }

  tags = {
    Name = each.key
  }
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                CORE-APP in ECS Rolling deployment                                                                 //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



/////////////////// Target group for the Core-App container

resource "aws_lb_target_group" "public_alb_core_app_target_group" {
  for_each = var.core_app

  # name                  = "PBL-${each.key}"
  name_prefix = "PBL-BE"
  port        = each.value.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "5"
    interval            = "30"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
    timeout             = "5"
    path                = "/health"
    unhealthy_threshold = "2"
  }

  stickiness {
    cookie_duration = 86400
    enabled         = false
    type            = "lb_cookie"
  }

  tags = {
    Name = "PBL-${each.key}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

// ALB listener

resource "aws_lb_listener" "public_alb_listener_core_app" {
  for_each = var.core_app

  load_balancer_arn = aws_lb.public_alb.id
  port              = each.value.port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.public_alb_core_app_target_group[each.key].arn
    type             = "forward"
  }
}




//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                MICROSERVICES in ECS Rolling deployment                                                           //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


///////////////////////// Application Load Balancer target group and listener rules


// Target group for the microservices containers

resource "aws_lb_target_group" "public_alb_microservice_target_group" {
  for_each = var.service

  # name                  = "PBL-${each.key}"
  name_prefix          = "PBL-AL"
  port                 = each.value.port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip" // requires health checks
  deregistration_delay = "60"

  health_check {
    enabled = true

    healthy_threshold   = "5"
    interval            = "30"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
    timeout             = "5"
    path                = "/health"
    unhealthy_threshold = "2"
  }

  stickiness {
    cookie_duration = 86400
    enabled         = false
    type            = "lb_cookie"
  }

  tags = {
    Name = "PBL-${each.key}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

// ALB listener

resource "aws_lb_listener" "public_alb_listener_microservice" {
  for_each = var.service

  load_balancer_arn = aws_lb.public_alb.id
  port              = each.value.port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.public_alb_microservice_target_group[each.key].arn
    type             = "forward"
  }
}
