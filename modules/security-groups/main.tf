# Security Group for ALB (Public API only)
resource "aws_security_group" "alb_public" {
  name        = "${var.app_name}-${var.environment}-alb"
  description = "Security group for ALB serving Kratos public API"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from Internet (redirected to HTTPS)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-${var.environment}-alb-sg"
    }
  )
}

# Security Group for ECS Tasks
# Public API: from ALB only. Admin API: from allowed SGs + VPC (restricted, no internet)
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.app_name}-${var.environment}-ecs-kratos"
  description = "Security group for ECS tasks. Public API via ALB; Admin API restricted to allowed SGs and VPC."
  vpc_id      = var.vpc_id

  ingress {
    description     = "Public API port from ALB only"
    from_port       = var.public_port
    to_port         = var.public_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_public.id]
  }

  dynamic "ingress" {
    for_each = length(var.allowed_security_group_ids) > 0 ? [1] : []
    content {
      description     = "Admin API port from allowed security groups only (no internet)"
      from_port       = var.admin_port
      to_port         = var.admin_port
      protocol        = "tcp"
      security_groups = var.allowed_security_group_ids
    }
  }

  ingress {
    description = "Admin API port from VPC (for internal service-to-service)"
    from_port   = var.admin_port
    to_port     = var.admin_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-${var.environment}-ecs-kratos-sg"
    }
  )
}
