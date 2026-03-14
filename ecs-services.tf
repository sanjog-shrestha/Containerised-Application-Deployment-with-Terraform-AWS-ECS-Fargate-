# ECS service running the application tasks behind the ALB
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  # Subnets and security groups for Fargate tasks; public IP for outbound traffic
  network_configuration {
    subnets = [
      aws_subnet.public_1.id,
      aws_subnet.public_2.id
    ]
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  # Attach this service to the ALB target group for HTTP traffic
  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "${var.project_name}-container"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http]

  # Prevent Terraform from overwriting desired_count changed by autoscaling
  lifecycle {
    ignore_changes = [desired_count]
  }
}