// This provisions a bastion host in a private subnet
// It can be accessed with a Session Manager
// IP tunnel is made from within the local machine through the bastion to any other resource in the private subnet - Aurora, Elasticache

// Obtaining pre-existing information

data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name = "name"
    # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type (first line of Amazon Linux AMI)
    values = ["amzn2-ami-kernel-5*-x86_64-gp2"]
  }
}

// Provisioning the Bastion host in a private subnet

resource "aws_instance" "private_bastion" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = var.instance_type
  associate_public_ip_address = false
  subnet_id                   = var.private_subnet_ids[0]
  vpc_security_group_ids      = [var.bastion_sg_id]
  iam_instance_profile        = aws_iam_instance_profile.bastion_private_instance_profile.name

  # https://www.terraform.io/language/functions/templatefile
  #user_data = templatefile("${path.module}/tpl/userdata.tpl", {})

  tags = {
    Name = "${var.environment}-${var.app_name}-bastion-host-private"
  }

  lifecycle {
    ignore_changes = [
      ami, disable_api_termination, ebs_optimized,
      hibernation, credit_specification,
      network_interface, ephemeral_block_device
    ]
  }
}

# IAM resources

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bastion_private_role" {
  name               = "${var.environment}-${var.app_name}-bastion-private-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "bastion_private_role_policy_attachment_SSM" {
  role       = aws_iam_role.bastion_private_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile
resource "aws_iam_instance_profile" "bastion_private_instance_profile" {
  name = "${var.environment}-${var.app_name}-bastion-private-instance-profile"
  role = aws_iam_role.bastion_private_role.name
}
