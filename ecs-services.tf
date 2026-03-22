# ECS service — runs Nginx tasks behind the ALB, registered via target group
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  # Tasks run in public subnets with public IPs so they can reach
  # ECR (image pull) and CloudWatch (log delivery) over the internet
  network_configuration {
    subnets = [
      aws_subnet.public_1.id,
      aws_subnet.public_2.id
    ]
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  # Register tasks with the ALB target group on port 80
  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "${var.project_name}-container"
    container_port   = 80
  }

  # Wait for the ALB listener and the ECR image push before starting tasks.
  # Without null_resource.push_nginx_to_ecr here, tasks start before the
  # image exists in ECR and immediately fail with CannotPullContainerError.
  depends_on = [
    aws_lb_listener.http,
    null_resource.push_nginx_to_ecr
  ]

  # Prevent Terraform from overwriting desired_count managed by autoscaling
  lifecycle {
    ignore_changes = [desired_count]
  }
}