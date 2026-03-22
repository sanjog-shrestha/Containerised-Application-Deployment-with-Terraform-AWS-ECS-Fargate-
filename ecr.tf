# ECR repository for storing the application container images
resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Lifecycle policy — retain only the 10 most recent images
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

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

# IAM policy granting ECS execution role least-privilege ECR pull access
resource "aws_iam_role_policy" "ecr_pull" {
  name = "${var.project_name}-ecr-pull-policy"
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

# Write a .cmd script to disk first, then execute it.
# This bypasses all PowerShell pipe/encoding issues entirely.
# CMD pipes are handled natively by the OS — no variable corruption.
resource "local_file" "ecr_push_script" {
  filename = "${path.module}/ecr_push.cmd"
  content  = <<-EOT
    @echo off
    echo Step 1 - Authenticating and pushing Nginx to ECR...
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${trimsuffix(split("/", aws_ecr_repository.app.repository_url)[0], "")}
    if %errorlevel% neq 0 (
      echo ERROR: Docker login failed
      exit /b 1
    )
    echo Step 2 - Pulling Nginx...
    docker pull nginx:latest
    if %errorlevel% neq 0 (
      echo ERROR: docker pull failed
      exit /b 1
    )
    echo Step 3 - Tagging...
    docker tag nginx:latest ${aws_ecr_repository.app.repository_url}:latest
    if %errorlevel% neq 0 (
      echo ERROR: docker tag failed
      exit /b 1
    )
    echo Step 4 - Pushing to ECR...
    docker push ${aws_ecr_repository.app.repository_url}:latest
    if %errorlevel% neq 0 (
      echo ERROR: docker push failed
      exit /b 1
    )
    echo Done - Nginx pushed to ECR successfully.
  EOT
}

resource "null_resource" "push_nginx_to_ecr" {
  triggers = {
    ecr_repository_url = aws_ecr_repository.app.repository_url
  }

  # Execute the .cmd script using cmd.exe directly — no PowerShell pipe issues
  provisioner "local-exec" {
    interpreter = ["cmd", "/C"]
    command     = "${path.module}\\ecr_push.cmd"
  }

  depends_on = [
    aws_ecr_repository.app,
    aws_iam_role_policy.ecr_pull,
    local_file.ecr_push_script,
  ]
}