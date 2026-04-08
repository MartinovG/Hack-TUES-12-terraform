# VPC 
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.environment}-${var.app_name}-vpc"
  }
}

# Public subnets
resource "aws_subnet" "public_subnet" {
  count                   = length(var.public_subnets_cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.public_subnets_cidr, count.index)
  availability_zone       = "${var.region}${element(var.availability_zones, count.index)}"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.environment}-${var.app_name}-public-subnet-${element(var.availability_zones, count.index)}"
  }
}

# Private subnets
resource "aws_subnet" "private_subnet" {
  count                   = length(var.private_subnets_cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.private_subnets_cidr, count.index)
  availability_zone       = "${var.region}${element(var.availability_zones, count.index)}"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.environment}-${var.app_name}-private-subnet-${element(var.availability_zones, count.index)}"
  }
}

# CodeBuild private subnets
resource "aws_subnet" "codebuild_private_subnet" {
  count                   = length(var.codebuild_private_subnets_cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.codebuild_private_subnets_cidr, count.index)
  availability_zone       = "${var.region}${element(var.availability_zones, count.index)}"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.environment}-${var.app_name}-codebuild-subnet-${element(var.availability_zones, count.index)}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "public_igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.environment}-${var.app_name}-public-igw" }
}

# NAT eip
resource "aws_eip" "nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.public_igw]
}

resource "aws_nat_gateway" "public_nat" {
  connectivity_type = "public"
  allocation_id     = aws_eip.nat_eip.id
  subnet_id         = element(aws_subnet.public_subnet.*.id, 0)
  tags              = { Name = "${var.environment}-${var.app_name}-nat-gateway-in-public-subnet-${element(var.availability_zones, 0)}" }
  depends_on        = [aws_internet_gateway.public_igw]
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.environment}-${var.app_name}-route-table-public" }
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.environment}-${var.app_name}-route-table-private" }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.public_igw.id
  depends_on             = [aws_route_table.public]
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.public_nat.id
  depends_on             = [aws_route_table.private]
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets_cidr)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "codebuild" {
  count          = length(var.codebuild_private_subnets_cidr)
  subnet_id      = element(aws_subnet.codebuild_private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

# Flow logs
resource "aws_flow_log" "main_vpc_flowlogs" {
  iam_role_arn    = aws_iam_role.main_vpc_flowlogs_role.arn
  log_destination = aws_cloudwatch_log_group.main_vpc_flowlogs_loggroup.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
  tags            = { Name = "${var.environment}-${var.app_name}-entire-vpc-flow-logging" }
}
resource "aws_cloudwatch_log_group" "main_vpc_flowlogs_loggroup" {
  name              = "/vpc/main-vpc-flowlogs-loggroup"
  retention_in_days = 7
}
resource "aws_iam_role" "main_vpc_flowlogs_role" {
  name               = "main-vpc-flowlogs-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {"Service": "vpc-flow-logs.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy" "main_vpc_flowlogs_role_policy" {
  name   = "main-vpc-flowlogs-policy"
  role   = aws_iam_role.main_vpc_flowlogs_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {"Action": ["logs:CreateLogStream","logs:PutLogEvents","logs:DescribeLogGroups","logs:DescribeLogStreams"],"Effect": "Allow","Resource": "*"}
  ]
}
EOF
}