// This file specifies the required providers and their versions for the Terraform configuration.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}