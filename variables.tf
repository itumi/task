variable "aws_region" {
  type    = string
  default = "us-west-1"
}

variable "aws_s3_bucket" {
  description = "S3 Bucket for Zip"
}

locals {
  routes = {
    "index" : {
      name : "index"
      http_verb : "GET"
      path = "/"
      policies : "logs:List*",
      resource : "arn:aws:logs:*:*:*"

    }
  }
}
