# ECS Cluster for Hydra
resource "aws_ecs_cluster" "hydra" {
  name = "${var.app_name}-${var.environment}-hydra"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-${var.environment}-hydra-cluster"
    }
  )
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.app_name}-${var.environment}-hydra-task-execution-role"

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

# Secrets Manager policy for task execution role
resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  count = length(var.hydra_secrets_manager_secret_arns) > 0 ? 1 : 0

  name = "${var.app_name}-${var.environment}-hydra-task-execution-secrets"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.hydra_secrets_manager_secret_arns
      }
    ]
  })
}

# CloudWatch Logs policy for task execution role
resource "aws_iam_role_policy" "ecs_task_execution_logs" {
  name = "${var.app_name}-${var.environment}-hydra-task-execution-logs"
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
          "${var.hydra_log_group_arn}:*"
        ]
      }
    ]
  })
}

# Task Definition: config-downloader -> hydra-migrate (init) -> hydra (service)
resource "aws_ecs_task_definition" "hydra" {
  family                   = "${var.app_name}-${var.environment}-hydra"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.hydra_cpu
  memory                   = var.hydra_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = var.hydra_ecs_task_role_arn

  container_definitions = jsonencode([
    # 1. Download config from S3
    {
      name      = "config-downloader"
      image     = "amazon/aws-cli:latest"
      essential = false

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.hydra_log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs-init"
        }
      }

      entryPoint = ["/bin/sh", "-c"]

      environment = [
        {
          name  = "S3_BUCKET"
          value = var.hydra_s3_config_bucket_name
        },
        {
          name  = "CONFIG_KEY"
          value = var.hydra_s3_config_key
        },
        {
          name  = "CONFIG_PATH"
          value = "/etc/config/hydra"
        }
      ]

      command = [
        "mkdir -p $${CONFIG_PATH} && aws s3 cp s3://$${S3_BUCKET}/$${CONFIG_KEY} $${CONFIG_PATH}/hydra-config.yaml && chmod 644 $${CONFIG_PATH}/hydra-config.yaml && echo 'Config downloaded successfully'"
      ]

      mountPoints = [
        {
          sourceVolume  = "hydra-config"
          containerPath = "/etc/config/hydra"
          readOnly      = false
        }
      ]
    },
    # 2. Run database migrations (init container)
    {
      name      = "hydra-migrate"
      image     = "${var.hydra_image}:${var.hydra_image_tag}"
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
          "awslogs-group"         = var.hydra_log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs-migrate"
        }
      }

      environment = var.hydra_environment_vars

      secrets = var.hydra_secrets

      command = ["migrate", "sql", "-e", "--yes", "-c", "/etc/config/hydra/hydra-config.yaml"]

      mountPoints = [
        {
          sourceVolume  = "hydra-config"
          containerPath = "/etc/config/hydra"
          readOnly      = true
        }
      ]
    },
    # 3. Hydra service (starts only after migration succeeds)
    {
      name      = "hydra"
      image     = "${var.hydra_image}:${var.hydra_image_tag}"
      essential = true

      dependsOn = [
        {
          containerName = "hydra-migrate"
          condition     = "SUCCESS"
        }
      ]

      portMappings = [
        {
          containerPort = var.hydra_public_port
          protocol      = "tcp"
        },
        {
          containerPort = var.hydra_admin_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.hydra_log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      environment = var.hydra_environment_vars

      secrets = var.hydra_secrets

      command = ["serve", "all", "-c", "/etc/config/hydra/hydra-config.yaml"]

      mountPoints = [
        {
          sourceVolume  = "hydra-config"
          containerPath = "/etc/config/hydra"
          readOnly      = true
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:${var.hydra_public_port}/health/alive || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  volume {
    name = "hydra-config"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-${var.environment}-hydra-task-def"
    }
  )
}

# Service Discovery: Admin API accessible via private DNS
resource "aws_service_discovery_private_dns_namespace" "hydra" {
  name        = "${var.app_name}-${var.environment}-hydra.local"
  description = "Private DNS namespace for Hydra admin API"
  vpc         = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-${var.environment}-hydra-namespace"
    }
  )
}

resource "aws_service_discovery_service" "hydra_admin" {
  name = "hydra-admin"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.hydra.id

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
      Name = "${var.app_name}-${var.environment}-hydra-admin-discovery"
    }
  )
}

# ECS Service: Public API via ALB; Admin API via Service Discovery
resource "aws_ecs_service" "hydra" {
  name            = "${var.app_name}-${var.environment}-hydra"
  cluster         = aws_ecs_cluster.hydra.id
  task_definition = aws_ecs_task_definition.hydra.arn
  desired_count   = var.hydra_desired_count

  dynamic "capacity_provider_strategy" {
    for_each = var.use_fargate_spot ? [1] : []
    content {
      capacity_provider = "FARGATE_SPOT"
      weight            = 10
      base              = 0
    }
  }
  dynamic "capacity_provider_strategy" {
    for_each = var.use_fargate_spot ? [1] : []
    content {
      capacity_provider = "FARGATE"
      weight            = 1
      base              = 0
    }
  }
  launch_type = var.use_fargate_spot ? null : "FARGATE"  # null when using capacity_provider_strategy

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.hydra_ecs_tasks_security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.hydra_target_group_arn
    container_name   = "hydra"
    container_port   = var.hydra_public_port
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.hydra_admin.arn
    container_name = "hydra"
  }

  depends_on = [
    aws_ecs_task_definition.hydra,
    var.hydra_target_group_arn
  ]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-${var.environment}-hydra-service"
    }
  )
}
