variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "aws_s3_bucket" {
  description = "S3 Bucket for Zip"
}

variable "vpc_id" {
  description = "ID of an existing VPC"
  type        = string
}

variable "subnets" {
  description = "Subnets in different Availability Zones"
  type        = list(string)
  default     = ["subnet-12345678", "subnet-87654321"]  # Ensure these are in different Availability Zones
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
