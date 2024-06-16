AWS Deployment with Terraform

Overview

This project deploys a simple static application using AWS and Terraform. 
The infrastructure includes a VPC, subnets, security groups, an internet gateway, a route table, a load balancer, and an auto-scaling group. 
The application is deployed using GitHub Actions to automate the process.

Prerequisites

- AWS user policies:
    AmazonAPIGatewayAdministrator
    AmazonDynamoDBFullAccess
    AmazonEC2FullAccess
    AmazonS3FullAccess
    AmazonVPCFullAccess
    AWSLambda_FullAccess
    CloudWatchFullAccess
    IAMFullAccess
- Github Secrets:
    AWS_ACCESS_KEY_ID
    AWS_SECRET_ACCESS_KEY
    AWS_AMI_ID
    AWS_REGION
    AWS_S3_BUCKET

Setup

Clone the Repository

git clone https://github.com/your-repo/your-project.git
cd your-project

Configure AWS Credentials

Ensure your AWS CLI is configured with the necessary access keys and permissions. You can do this by running:

aws configure

Initialize Terraform

Navigate to the project directory and initialize Terraform:

terraform init

Plan and Apply Terraform Configuration

Plan the infrastructure changes and apply them:

terraform plan
terraform apply -auto-approve

Deployment

The deployment is automated using GitHub Actions. Every push to the main branch triggers the deployment workflow defined in deploy.yaml.

GitHub Actions Workflow

The workflow performs the following steps:
1. Checks out the code.
2. Sets up Node.js and installs dependencies.
3. Builds the React application.
4. Archives the build artifacts and uploads them to an S3 bucket.
5. Initializes Terraform and applies the configuration.

Secrets

Ensure the following secrets are set in your GitHub repository:
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_REGION
- AWS_S3_BUCKET
- AWS_AMI_ID

Variables

The following variables are defined in variables.tf to make the infrastructure configurable:

- aws_region: The AWS region to deploy in (default: us-west-2).
- vpc_cidr: The CIDR block for t
