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

variable "subnets" {
  description = "Subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
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

variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "aws_ami_id" {
  description = "AMI ID for the instances"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}
