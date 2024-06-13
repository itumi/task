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
