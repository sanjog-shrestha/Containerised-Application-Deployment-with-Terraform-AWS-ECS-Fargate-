// Key outputs for accessing and observing the deployed infrastructure
output "alb_dns_name" {
  description = "DNS name of the Load Balancer"
  value       = aws_lb.main.dns_name
}

output "app_url" {
  description = "Full URL to access your application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ecs_service_name" {
  description = "Name of the ECS Service"
  value       = aws_ecs_service.app.name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

output "ecr_repository_url" {
  description = "ECR repository URL - use this to tag & push your image"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_push_commands" {
  description = "Ready-to-use commands to authenticate, tag, and push your image to ECR"
  value       = <<-EOT
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.app.repository_url}
    docker build -t ${var.project_name} .
    docker tag ${var.project_name}:latest ${aws_ecr_repository.app.repository_url}:latest
    docker push ${aws_ecr_repository.app.repository_url}:latest
  EOT
}

