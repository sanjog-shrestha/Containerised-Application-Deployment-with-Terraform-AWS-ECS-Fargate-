# -----------------------------------------------------------------------------
# Target Group
# Routes HTTP traffic to ECS Fargate tasks using IP-based targeting.
# CloudFront sits in front and handles HTTPS — ALB only needs port 80.
# -----------------------------------------------------------------------------

resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  # Health check on / — ECS task must return HTTP 200 to be marked healthy
  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
  }
}

# -----------------------------------------------------------------------------
# Application Load Balancer
# Internet-facing, spans both public subnets for AZ redundancy.
# Receives HTTP from CloudFront — no HTTPS listener required here.
# -----------------------------------------------------------------------------

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]
}

# -----------------------------------------------------------------------------
# HTTP Listener — port 80 only.
# HTTPS is terminated at CloudFront. The ALB receives plain HTTP from
# CloudFront and forwards it to ECS tasks. No HTTPS listener needed.
# -----------------------------------------------------------------------------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}