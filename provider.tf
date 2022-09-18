# Please setup your backend , this is example for AWS S3
terraform {
  backend "s3" {
    bucket = "example-tf-state"
    key    = "tf_state"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
