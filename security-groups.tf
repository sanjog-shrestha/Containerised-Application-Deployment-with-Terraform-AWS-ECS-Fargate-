# Security group for the Application Load Balancer.
# Only port 80 is needed — CloudFront handles HTTPS externally.
# CloudFront forwards requests to the ALB over HTTP on port 80.
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Controls traffic to the Load Balancer"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP from anywhere — CloudFront origin requests arrive on port 80
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic to ECS tasks and internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for ECS tasks.
# Only the ALB security group can send traffic to containers on port 80.
# No direct public access to containers is permitted.
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Controls traffic to ECS containers"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP only from the ALB security group
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow all outbound — required for ECR image pulls and CloudWatch log writes
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}