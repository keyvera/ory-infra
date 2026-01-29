# Single ALB for Kratos Public API
# Admin API is accessed via Service Discovery (internal); restricted by ECS security group
resource "aws_lb" "public" {
  name               = "${var.app_name}-${var.environment}-kratos"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.environment == "prod" ? true : false
  enable_http2              = true
  idle_timeout              = 60

  access_logs {
    bucket  = var.access_logs_bucket
    enabled = var.access_logs_enabled
    prefix  = "${var.app_name}-${var.environment}-kratos"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-${var.environment}-kratos-alb"
    }
  )
}

# Target Group for Public API
resource "aws_lb_target_group" "public" {
  name                 = "${var.app_name}-${var.environment}-kratos-public"
  port                 = var.public_port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health/ready"
    protocol            = "HTTP"
    matcher             = "200"
  }

  stickiness {
    enabled = false
    type    = "lb_cookie"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-${var.environment}-kratos-public-tg"
    }
  )
}

# HTTPS Listener
resource "aws_lb_listener" "public_https" {
  load_balancer_arn = aws_lb.public.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public.arn
  }
}

# HTTP Listener (redirects to HTTPS)
resource "aws_lb_listener" "public_http" {
  load_balancer_arn = aws_lb.public.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
