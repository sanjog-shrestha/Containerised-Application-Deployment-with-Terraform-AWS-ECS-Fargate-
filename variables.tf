// Core input variables for this project
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

// Name used for tagging and resource naming
variable "project_name" {
  description = "Project name used for all resource naming"
  type        = string
}
