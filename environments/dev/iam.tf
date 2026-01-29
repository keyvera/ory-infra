# ECS Task Role for Kratos (created separately to avoid circular dependency)
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

# ECS Task Role for Hydra (S3 config read, etc.)
resource "aws_iam_role" "ecs_task_hydra" {
  name = "${var.app_name}-${var.environment}-hydra-task-role"

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
