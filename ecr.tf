# ECR repository for storing the application container images
resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-repo"
  image_tag_mutability = "MUTABLE"

  # Enable vulnerability scanning when images are pushed
  image_scanning_configuration {
    scan_on_push = true
  }
}

# Lifecycle policy to retain only the 10 most recent images and expire older ones
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  # JSON policy: one rule to expire images when count exceeds 10
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the 10 most recent images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }

        action = {
          type = "expire"
        }
      }
    ]
  })
}

# IAM policy allowing ECS execution role to pull images from ECR
resource "aws_iam_role_policy" "ecr_pull" {
  name = "${var.project_name}-ecr-rull-policy"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}