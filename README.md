# Pgadmin + rds deployment.

This terraform module deploys a database and pgadmin frontend to manage RDS.

The database is AWS RDS Postgres in one AZ.
The frontend use pgadmin in an ECS orchestrated container.

External connection is made via ELB ALB.

Route53 is used to create DNS zones, names, and certificates that are installed in the ALB listener.
Deployment requires the ability to manage the DNS zone that will be used.


All secrets are generated in the first deployment for each environment and stored in the SSM parameter store.

## High-level resource list

- Set of route53 records.
- Certificate and certificate validation.
- ELB (Based on Application load balancer).
- ECS cluster + service.
- Rendered task definition.
- ASG based on ec2 launch configuration for ECS.
- RDS Postgres database.
- VPC + subnets in two, (by default) availability zones.
- basic IAM roles.
- Security groups.
- SSM parameter store for secure strings.


Mostly all recourses have comments.
Almost every variable and output has description.

## Backend
By default, backend is S3 in AWS, please configure this block for your desired backend.

```hcl 
# Please setup your backend , this is example for AWS S3.
terraform {
  backend "s3" {
    bucket = "example-tf-state"
    key    = "tf_state"
    region = "us-east-1"
  }
```

## Usage

Setup your AWS credentials
- using environment variables
- using '~/.aws/credentials' file
- using terraform config files

Run initialization and deployment 

```bash

terraform init
terraform apply 

#you can deploy specific environment by using '--target' flag like this 

terraform apply --target=module.pg-admin-stage
terraform apply --target=module.pg-admin-prod
```

After successful deployment, you will receive URL of pgadmin site and path in SSM which stores passwords for services.

## Known bugs
- Pgadmin configuration 

I'm still working on setting up automatic connection between pgadmin and RDS during deployment, so far I haven't figured out how to use the IAM roles for this and configure the connection, so the first time you connect, you need to enter a password in the pgadmin console.

However, deployment generates a Pgadmin connection configuration file (server.json), so you don't have to configure the connection yourself, just enter the password.

The password can be viewed in SSM.


## To Do

- Refactor AIM roles for ECS.

You need to define IAM roles for each environment, the role that is generated during deployment has rights to all resources in the account.

However, access to resources is limited by VPC isolation.
But for best practices, IAM role generation needs to be redone

- Refactor network stack.

Alter launch configuration and ELB so that public ip addresses can be removed.
At the moment, access to instance is limited by security groups.

- Use IAM roles to access RDS.

Currently, connecting to RDS requires a password stored in the SSM parameter store.

- Draw a diagram.

- Set up logs, monitoring and alarms.
