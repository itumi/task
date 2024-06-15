variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "aws_s3_bucket" {
  description = "S3 Bucket for Zip"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  default     = "10.0.0.0/16"
}

variable "vpc_subnets" {
  description = "Subnets in different Availability Zones for VPC"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]  # CIDR blocks for VPC subnets
}

variable "lb_subnet_ids" {
  description = "List of subnet IDs for the load balancer"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "security_group_name" {
  description = "Name of the security group"
  default     = "webapp-sg"
}

variable "allowed_ports" {
  description = "List of allowed ports for the security group"
  type        = list(number)
  default     = [80, 443]
}

variable "app_name" {
  description = "Name of the application"
  default     = "myapp"
}
