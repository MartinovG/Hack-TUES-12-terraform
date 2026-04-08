
/////////////////////////////////// Security groups for the major AWS services


// ALB Security Group

resource "aws_security_group" "alb_sg" {
  name        = "${var.environment}-${var.app_name} - ALB SecurityGroup"
  description = "ALB Allowed Ports"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-${var.app_name} - ALB SecurityGroup"
  }

  lifecycle {
    create_before_destroy = false // Necessary if changing 'name' or 'name_prefix' properties.
  }
}

resource "aws_security_group_rule" "alb_sg_ingress_80" {
  description       = "HTTPS Traffic from Internet"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}
resource "aws_security_group_rule" "alb_sg_ingress_443" {
  description       = "HTTPS Traffic from Internet"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}
resource "aws_security_group_rule" "alb_sg_ingress_core_app" {
  for_each = var.core_app

  description = "HTTPS Traffic from Core-app"
  type        = "ingress"
  from_port   = each.value.external_port
  to_port     = each.value.external_port
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  # source_security_group_id  = aws_security_group.ecs_sg.id
  security_group_id = aws_security_group.alb_sg.id
}
resource "aws_security_group_rule" "alb_sg_ingress_services" {
  for_each = var.service

  description = "HTTPS Traffic from ${each.key}"
  type        = "ingress"
  from_port   = each.value.external_port
  to_port     = each.value.external_port
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  # source_security_group_id  = aws_security_group.ecs_sg.id
  security_group_id = aws_security_group.alb_sg.id
}
resource "aws_security_group_rule" "alb_sg_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}




// ECS Cluster Security Group

resource "aws_security_group" "ecs_sg" {
  name        = "${var.environment}-${var.app_name} - ECS SecurityGroup"
  description = "ECS Allowed Ports"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-${var.app_name} - ECS SecurityGroup"
  }

  lifecycle {
    create_before_destroy = false // Necessary if changing 'name' or 'name_prefix' properties.
  }
}
resource "aws_security_group_rule" "ecs_sg_ingress_alb" {
  type                     = "ingress"
  description              = "Traffic from ALB open for all ports and protocols"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id        = aws_security_group.ecs_sg.id
}
resource "aws_security_group_rule" "ecs_sg_ingress_all_from_self" {
  type              = "ingress"
  description       = "Allow all traffic from self"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # All protocols
  security_group_id = aws_security_group.ecs_sg.id
  self              = true # Allow traffic from the same SG

}
resource "aws_security_group_rule" "ecs_sg_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_sg.id
}



// Codebuild Security Group

resource "aws_security_group" "codebuild_sg" {
  name        = "${var.environment}-${var.app_name} - CODEBUILD SecurityGroup"
  description = "Codebuild Allowed Ports"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = false
  }

  tags = {
    Name = "${var.environment}-${var.app_name} - CODEBUILD SecurityGroup"
  }

  lifecycle {
    create_before_destroy = false // Necessary if changing 'name' or 'name_prefix' properties.
  }
}



// Bastion Host in a private subnet - Security Group - allowing SSM connection to the RDS and elasticache

resource "aws_security_group" "bastion_sg" {
  name        = "${var.environment}-${var.app_name} - PrivateBastion SecurityGroup"
  description = "Private subnet Bastion Security Group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-${var.app_name} - PrivateBastion SecurityGroup"
  }

  lifecycle {
    create_before_destroy = false // Necessary if changing 'name' or 'name_prefix' properties.
  }
}

resource "aws_security_group_rule" "bastion_sg_egress" {
  type              = "egress"
  description       = "Traffic to all VPC resources"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion_sg.id
}



// PostgreSQL security group
resource "aws_security_group" "docdb_sg" {
  name        = "${var.environment}-${var.app_name} - PostgreSQL SecurityGroup"
  description = "PostgreSQL accessible from within the VPC only"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "${var.environment}-${var.app_name} - PostgreSQL SecurityGroup"
  }
}
resource "aws_security_group_rule" "docdb_sg_ingress_bastion" {
  type                     = "ingress"
  description              = "Bastion host access"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion_sg.id
  security_group_id        = aws_security_group.docdb_sg.id
}
resource "aws_security_group_rule" "docdb_sg_ingress_backend" {
  type                     = "ingress"
  description              = "Backend access"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_sg.id
  security_group_id        = aws_security_group.docdb_sg.id
}
resource "aws_security_group_rule" "docdb_sg_egress_internet" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.docdb_sg.id
}
