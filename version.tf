# Terraform and provider version constraints
terraform {
  required_version = ">=1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # null provider — used by null_resource in ecr.tf to push Nginx to ECR
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    # local provider — used by local_file resources if needed
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}