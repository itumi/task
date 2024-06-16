Comment

Tried to build the infra as automated and as easy to conf as possible, 
this code could be improved by making checks for everything before creating, 
but for first time setup the checks are not needed.
For larger scale projects the code could be modulated (modules/vpc/main.tf etc.)

Overview

This project deploys a simple static application using AWS and Terraform.
The application is deployed using GitHub Actions to automate the process.
The infrastructure includes:
    - VPC, 
    - subnets
    - security groups
    - internet gateway
    - route table
    - load balancer
    - auto-scaling group

Prerequisites

- AWS CLI: Installed and configured with appropriate permissions (permissions given from gui for now):
    - AmazonEC2FullAccess
    - AmazonS3FullAccess
    - AmazonVPCFullAccess
    - IAMFullAccess
- GitHub repository secrets:
    - AWS_ACCESS_KEY_ID
    - AWS_SECRET_ACCESS_KEY
    - AWS_REGION
    - AWS_S3_BUCKET
    - AWS_AMI_ID

Deployment

The deployment is automated using GitHub Actions. Every push to the main branch triggers the deployment workflow defined in deploy.yaml.

GitHub Actions Workflow

The workflow performs the following steps:
1. Checks out the code.
2. Sets up Node.js and installs dependencies.
3. Builds the React application.
4. Archives the build artifacts and uploads them to an S3 bucket.
5. Initializes Terraform and applies the configuration.

Variables

The following variables are defined in variables.tf to make the infrastructure configurable:

- aws_region: The AWS region to deploy in (default: us-west-2).
- vpc_cidr: The CIDR block for the VPC (default: 10.0.0.0/16).
- subnets: A list of subnet CIDR blocks (default: ["10.0.1.0/24", "10.0.2.0/24"]).
- availability_zones: A list of availability zones (default: ["us-west-2a", "us-west-2b"]).
- security_group_name: The name of the security group (default: main-sg).

High Availability and Scalability

- Auto-Scaling Group: Configured to run across multiple availability zones with a minimum of 1 instance, a maximum of 3 instances, and a desired capacity of 2 instances.
- Load Balancer: Distributes traffic across instances in multiple availability zones.
