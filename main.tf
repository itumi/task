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
  upper   = false
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.app_name}-vpc"
  }
}

# Subnets
resource "aws_subnet" "main" {
  count = length(var.subnets)
  vpc_id     = aws_vpc.main.id
  cidr_block = element(var.subnets, count.index)

  tags = {
    Name = "${var.app_name}-subnet-${count.index}"
  }
}

# Security Group
resource "aws_security_group" "main" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.security_group_name
  }
}

resource "aws_security_group" "lb_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-lb-sg"
  }
}

# Load Balancer
resource "aws_lb" "app" {
  name               = "myapp-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = distinct(var.lb_subnets)

  enable_deletion_protection = false

  tags = {
    Name = "myapp-lb"
  }
}

resource "aws_lb_target_group" "app" {
  name     = "myapp-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200-299"
  }

  tags = {
    Name = "myapp-tg"
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

# IAM Role
resource "aws_iam_role" "autoscaling_role" {
  name = "autoscaling-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "autoscaling_instance_profile" {
  name = "autoscaling_instance_profile"
  role = aws_iam_role.autoscaling_role.name

  lifecycle {
    ignore_changes = [
      name,
    ]
  }
}

# Launch Configuration
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

# Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  desired_capacity          = 2
  max_size                  = 3
  min_size                  = 1
  vpc_zone_identifier       = var.subnets
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
