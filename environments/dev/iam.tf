# ECS Task Role (created separately to avoid circular dependency)
resource "aws_iam_role" "ecs_task" {
  name = "${var.app_name}-${var.environment}-kratos-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}
