provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source  = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
}

module "subnets" {
  source = "./modules/subnets"
  vpc_id = module.vpc.vpc_id
  subnets = var.subnets
}

module "security_group" {
  source             = "./modules/security_group"
  vpc_id             = module.vpc.vpc_id
  security_group_name = var.security_group_name
  allowed_ports      = var.allowed_ports
}

# Launch Configuration
resource "aws_launch_configuration" "app" {
  name          = "app-launch-configuration"
  image_id      = var.ami_id
  instance_type = var.instance_type
  security_groups = [module.security_group.security_group_id]

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
  vpc_zone_identifier  = module.subnets.subnet_ids

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

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "subnet_ids" {
  value = module.subnets.subnet_ids
}

output "security_group_id" {
  value = module.security_group.security_group_id
}

output "autoscaling_group_id" {
  value = aws_autoscaling_group.app.id
}
