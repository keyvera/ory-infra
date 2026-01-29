# ECS Cluster
resource "aws_ecs_cluster" "kratos" {
  name = "${var.app_name}-${var.environment}-kratos"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-${var.environment}-kratos-cluster"
    }
  )
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.app_name}-${var.environment}-kratos-task-execution-role"

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

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Secrets Manager policy for task execution role (required for pulling secrets into containers)
resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  count = length(var.secrets_manager_secret_arns) > 0 ? 1 : 0

  name = "${var.app_name}-${var.environment}-kratos-task-execution-secrets"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.secrets_manager_secret_arns
      }
    ]
  })
}

# CloudWatch Logs policy for task execution role
resource "aws_iam_role_policy" "ecs_task_execution_logs" {
  name = "${var.app_name}-${var.environment}-kratos-task-execution-logs"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "${var.kratos_log_group_arn}:*"
        ]
      }
    ]
  })
}

# Single Task Definition: config-downloader -> kratos-migrate (init) -> kratos (service)
# Migration runs first on every task start; Kratos serve starts only after migration succeeds
resource "aws_ecs_task_definition" "kratos" {
  family                   = "${var.app_name}-${var.environment}-kratos"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    # 1. Download config from S3
    {
      name      = "config-downloader"
      image     = "amazon/aws-cli:latest"
      essential = false

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.kratos_log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs-init"
        }
      }

      entryPoint = ["/bin/sh", "-c"]

      environment = [
        {
          name  = "S3_BUCKET"
          value = var.s3_config_bucket_name
        },
        {
          name  = "CONFIG_PATH"
          value = "/etc/config/kratos"
        }
      ]

      command = [
        "mkdir -p $${CONFIG_PATH} && aws s3 cp s3://$${S3_BUCKET}/kratos-config.yaml $${CONFIG_PATH}/kratos-config.yaml && aws s3 cp s3://$${S3_BUCKET}/identity.schema.json $${CONFIG_PATH}/identity.schema.json && chmod -R 644 $${CONFIG_PATH}/* && echo 'Config files downloaded successfully'"
      ]

      mountPoints = [
        {
          sourceVolume  = "kratos-config"
          containerPath = "/etc/config/kratos"
          readOnly      = false
        }
      ]
    },
    # 2. Run database migrations (init container - must succeed before Kratos starts)
    # essential = false required: dependency containers (depended on with SUCCESS) cannot be essential
    {
      name      = "kratos-migrate"
      image     = "${var.kratos_image}:${var.kratos_image_tag}"
      essential = false

      dependsOn = [
        {
          containerName = "config-downloader"
          condition     = "SUCCESS"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.kratos_log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs-migrate"
        }
      }

      environment = var.kratos_environment_vars

      secrets = var.kratos_secrets

      command = ["migrate", "sql", "-e", "--yes"]

      mountPoints = [
        {
          sourceVolume  = "kratos-config"
          containerPath = "/etc/config/kratos"
          readOnly      = true
        }
      ]
    },
    # 3. Kratos service (starts only after migration completes successfully)
    {
      name      = "kratos"
      image     = "${var.kratos_image}:${var.kratos_image_tag}"
      essential = true

      dependsOn = [
        {
          containerName = "kratos-migrate"
          condition     = "SUCCESS"
        }
      ]

      # Single container exposes both public and admin ports
      portMappings = [
        {
          containerPort = var.public_port
          protocol      = "tcp"
        },
        {
          containerPort = var.admin_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.kratos_log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      environment = var.kratos_environment_vars

      secrets = var.kratos_secrets

      command = ["serve", "--config", "/etc/config/kratos/kratos-config.yaml", "--watch-courier"]

      mountPoints = [
        {
          sourceVolume  = "kratos-config"
          containerPath = "/etc/config/kratos"
          readOnly      = true
        }
      ]

      # Health check on public port (admin is internal-only)
      healthCheck = {
        command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:${var.public_port}/health/ready || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  volume {
    name = "kratos-config"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-${var.environment}-kratos-task-def"
    }
  )
}

# Service Discovery: Admin API accessible via private DNS (restricted by ECS security group)
resource "aws_service_discovery_private_dns_namespace" "kratos" {
  name        = "${var.app_name}.${var.environment}.local"
  description = "Private DNS namespace for Kratos admin API"
  vpc         = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-${var.environment}-kratos-namespace"
    }
  )
}

resource "aws_service_discovery_service" "kratos_admin" {
  name = "kratos-admin"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.kratos.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-${var.environment}-kratos-admin-discovery"
    }
  )
}

# ECS Service: Public API via ALB; Admin API via Service Discovery (VPC-only, SG-restricted)
resource "aws_ecs_service" "kratos" {
  name            = "${var.app_name}-${var.environment}-kratos"
  cluster         = aws_ecs_cluster.kratos.id
  task_definition = aws_ecs_task_definition.kratos.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.ecs_tasks_security_group_id]
    assign_public_ip = true
  }

  # Public API: identity.oauthentra.com -> ALB -> port 4433
  load_balancer {
    target_group_arn = var.public_target_group_arn
    container_name   = "kratos"
    container_port   = var.public_port
  }

  # Admin API: kratos-admin.<namespace> -> port 4434 (VPC-only, restricted by ECS SG)
  service_registries {
    registry_arn   = aws_service_discovery_service.kratos_admin.arn
    container_name = "kratos"
    # container_port = var.admin_port
  }

  depends_on = [
    aws_ecs_task_definition.kratos,
    var.public_target_group_arn
  ]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-${var.environment}-kratos-service"
    }
  )
}
