# ECS cluster hosting the Fargate services
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  # Enable Container Insights for metrics and logs in CloudWatch
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Capacity providers: Fargate (70% base) and Fargate Spot (30%) for cost savings
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  # Prefer standard Fargate; at least 1 task on FARGATE
  default_capacity_provider_strategy {
    base              = 1
    weight            = 70
    capacity_provider = "FARGATE"
  }

  # Remaining capacity can use Fargate Spot for lower cost
  default_capacity_provider_strategy {
    weight            = 30
    capacity_provider = "FARGATE_SPOT"
  }
}