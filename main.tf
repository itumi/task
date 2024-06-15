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

# Subnets in multiple AZs
resource "aws_subnet" "main" {
  count = length(var.subnets)
  vpc_id = aws_vpc.main.id
  cidr_block = element(var.subnets, count.index)
  availability_zone = element(var.azs, count.index)
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

# Load Balancer
resource "aws_lb" "main" {
  name               = "main-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.main.id]
  subnets            = aws_subnet.main[*].id
}

# Target Group
resource "aws_lb_target_group" "main" {
  name     = "main-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# Listener
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# EC2 Instances
resource "aws_instance" "web" {
  count         = 2
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = element(aws_subnet.main[*].id, count.index)
  security_groups = [aws_security_group.main.name]

  tags = {
    Name = "web-${count.index}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Register EC2 instances with the target group
resource "aws_lb_target_group_attachment" "web" {
  count            = 2
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = element(aws_instance.web[*].id, count.index)
  port             = 80
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

output "lb_dns_name" {
  value = aws_lb.main.dns_name
}
