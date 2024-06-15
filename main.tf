terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "la-pa"
    region = "us-west-2"
    key    = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
}

# Random string for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
}

# Data source to get the latest Amazon Linux 2 AMI
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create a new VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.app_name}-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.app_name}-igw"
  }
}

# Create Subnets
resource "aws_subnet" "main" {
  count                   = length(var.subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.subnets, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.app_name}-subnet-${count.index}"
  }
}

# Create Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.app_name}-rt"
  }
}

# Associate Route Table with Subnets
resource "aws_route_table_association" "a" {
  count          = length(var.subnets)
  subnet_id      = element(aws_subnet.main[*].id, count.index)
  route_table_id = aws_route_table.main.id
}

# Security Group
resource "aws_security_group" "main" {
  name        = var.security_group_name
  description = "Allow web traffic"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.allowed_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-sg"
  }
}

# Load Balancer
resource "aws_lb" "app" {
  name               = "${var.app_name}-lb-${random_string.suffix.result}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.main.id]
  subnets            = aws_subnet.main[*].id

  enable_deletion_protection = false

  tags = {
    Name = "${var.app_name}-lb"
  }
}

resource "aws_lb_target_group" "app" {
  name     = "${var.app_name}-tg-${random_string.suffix.result}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path     = "/"
    protocol = "HTTP"
  }

  tags = {
    Name = "${var.app_name}-tg"
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# IAM Role for Auto Scaling
resource "aws_iam_role" "autoscaling_role" {
  name = "autoscaling_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "autoscaling.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "autoscaling_policy_attachment" {
  role       = aws_iam_role.autoscaling_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_instance_profile" "autoscaling_instance_profile" {
  name = "autoscaling_instance_profile"
  role = aws_iam_role.autoscaling_role.name
}

# Auto Scaling Group
resource "aws_launch_configuration" "app" {
  name          = "app-launch-config-${random_string.suffix.result}"
  image_id      = data.aws_ami.latest_amazon_linux.id
  instance_type = var.instance_type

  security_groups = [aws_security_group.main.id]
  iam_instance_profile = aws_iam_instance_profile.autoscaling_instance_profile.name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  desired_capacity          = 2
  max_size                  = 3
  min_size                  = 1
  vpc_zone_identifier       = aws_subnet.main[*].id
  target_group_arns         = [aws_lb_target_group.app.arn]
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_configuration = aws_launch_configuration.app.id

  tag {
    key                 = "Name"
    value               = "${var.app_name}-asg"
    propagate_at_launch = true
  }
}

# Outputs
output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = aws_subnet.main[*].id
}

output "security_group_id" {
  value = aws_security_group.main.id
}

output "load_balancer_dns_name" {
  value = aws_lb.app.dns_name
}
