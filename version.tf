# Terraform and provider version constraints
terraform {
  required_version = ">=1.14.0"
  # AWS provider from HashiCorp, major version 5.x
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}