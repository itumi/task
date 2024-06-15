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

# VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

# Subnets
resource "aws_subnet" "main" {
  count = length(var.subnets)
  vpc_id = aws_vpc.main.id
  cidr_block = element(var.subnets, count.index)
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
}

# Launch Configuration
resource "aws_launch_configuration" "app" {
  name          = "app-launch-configuration"
  image_id      = var.ami_id
  instance_type = var.instance_type
  security_groups = [aws_security_group.main.id]

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  launch_configuration = aws_launch_configuration.app.id
  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity
  vpc_zone_identifier  = aws_subnet.main[*].id

  tag {
    key                 = "Name"
    value               = "app-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Scaling Policy - Scale Up
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
}

# Scaling Policy - Scale Down
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app.name
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

output "autoscaling_group_id" {
  value = aws_autoscaling_group.app.id
}
