# AWS provider configuration (region and default tags)
provider "aws" {
  # AWS region to use for all resources
  region = var.aws_region

  # Default tags applied to all supported AWS resources
  default_tags {
    tags = {
      Project = var.project_name
    }
  }
}