# Terraform managed API Gateway, Lambda, and DynamoDB

Used as boilerplate code to scaffold out a small serverless AWS application using [Terraform](https://www.terraform.io) which produces API Gateway routes, Lambda functions, and a DynamoDB table - includes correlating CloudWatch Logs.  
[Video Tutorial](https://www.youtube.com/watch?v=Ow0yM4Ebh6k)

#### NOTE - Creating this infrastructure may cause you to incur costs. Reference AWS pricing for more info.

## Installation

1.) You'll need an AWS account.

2.) Create an S3 bucket in your AWS account and replace the `api-gateway-lambda-dynamodb` bucket name in `main.tf` with your bucket name.

3.) `us-west-1` is hard coded in `main.tf`. If you're deploying this app to another region you need to update the `region` in `main.tf`.

4.) GitHub Actions Secrets:  
`AWS_ACCESS_KEY_ID`  
`AWS_SECRET_ACCESS_KEY`  
`AWS_REGION`  
`AWS_S3_BUCKET`  
`JWT_SECRET`

5.) AWS IAM user permissions required:  
`AmazonAPIGatewayAdministrator`  
`AWSLambda_FullAccess`  
`IAMFullAccess`  
`CloudWatchLogsFullAccess`  
`AmazonS3FullAccess`  
`AmazonDynamoDBFullAccess`

Can optionally be used with a domain name in a Hosted Zone in AWS Route 53. If you're using this repo with a domain name, rename the `domain.tf.txt` file to `domain.tf` so it's included when running the `terraform apply` command.

## How to import and existing Route 53 Zone

Run `terraform import aws_route53_zone.primary YOUR_ROUTE_53_ZONE_ID` (Replace YOUR_ROUTE_53_ZONE_ID with your Route 53 Hosted Zone ID).

## Renaming App Name

To support multiple deployments of this code (or a fork of this code) to AWS, I have littered the code with the label `yourapp` to support multiple functions, roles, and policies within the same AWS Account. Replace `yourapp` with your desired project name so you have the ability to deploy multiple versions (modified or not) of this repo within your AWS Account.

### Examples

This repo demonstrates multiple ways of serving content from Lambda, some of which may be considered unconventional (serving HTML files from Lambda). This is for simplification purposes minimizing the need for mulitple sub-domains (`www.yourdomainname.com` and `api.yourdomainname.com`) to serve static assets from one subdowmain using a CloudFront distrubution backed by and S3 bucket, and the other from API Gateway and Lambda.
