terraform {
  backend "s3" {
    encrypt    = true
    bucket     = "mg-terraform-state-storage"
    key        = "environment-iac/terraform.tfstate"
    region     = "aws_region_placeholder"
    access_key = "access_key_placeholder"
    secret_key = "secret_key_placeholder"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 1.0"
    }
  }
}


provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.aws_region
  default_tags {
    tags = var.tags
  }
}
