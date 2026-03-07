provider "aws" {
  # AWS region configuration
  region = var.aws_region

  # Default tags applied to all supported AWS resources
  default_tags {
    tags = {
      Project = var.project_name
    }
  }
}