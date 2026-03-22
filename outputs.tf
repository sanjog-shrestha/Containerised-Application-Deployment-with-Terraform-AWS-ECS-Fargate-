# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

# Primary application URL — HTTPS via CloudFront, fully trusted certificate.
# No custom domain, no browser warning, no self-signed cert required.
output "app_url" {
  description = "HTTPS URL via CloudFront — trusted certificate, no browser warning"
  value       = "https://${aws_cloudfront_distribution.app.domain_name}"
}

# Raw CloudFront domain name — useful for DNS records or CI/CD pipelines
output "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.app.domain_name
}

# CloudFront distribution ID — needed to trigger cache invalidations
output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.app.id
}

# ALB DNS name — internal origin used by CloudFront, not for direct access
output "alb_dns_name" {
  description = "ALB DNS name — internal origin, use app_url to access the app"
  value       = aws_lb.main.dns_name
}

# ECS service name — useful for AWS CLI queries and console navigation
output "ecs_service_name" {
  description = "Name of the ECS Service"
  value       = aws_ecs_service.app.name
}

# VPC ID
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

# Public subnet IDs
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

# ECR repository URL for tagging and pushing Docker images
output "ecr_repository_url" {
  description = "ECR repository URL - use this to tag and push your image"
  value       = aws_ecr_repository.app.repository_url
}

# Ready-to-use ECR push commands
output "ecr_push_commands" {
  description = "Commands to authenticate, tag, and push your image to ECR"
  value       = <<-EOT
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.app.repository_url}
    docker build -t ${var.project_name} .
    docker tag ${var.project_name}:latest ${aws_ecr_repository.app.repository_url}:latest
    docker push ${aws_ecr_repository.app.repository_url}:latest
  EOT
}