# Core input variables for this project

# AWS region where all resources will be deployed
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

# Project name used for resource naming and tagging
variable "project_name" {
  description = "Project name used for all resource naming"
  type        = string
}
