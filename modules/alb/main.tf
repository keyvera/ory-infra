# Shared ALB for Ory services (Kratos, Hydra)
# Host-based routing: identity.oauthentra.com -> Kratos, auth.oauthentra.com -> Hydra
# Admin APIs accessed via Service Discovery (internal); restricted by ECS security group
resource "aws_lb" "ory" {
  name               = "${var.app_name}-${var.environment}-ory"
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
    prefix  = "${var.app_name}-${var.environment}-ory"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-${var.environment}-ory-alb"
    }
  )
}

# Target Group for Kratos Public API
resource "aws_lb_target_group" "kratos" {
  name                 = "${var.app_name}-${var.environment}-kratos-public"
  port                 = var.kratos_public_port
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
      Name = "${var.app_name}-${var.environment}-kratos-tg"
    }
  )
}

# Target Group for Hydra Public API (OAuth2/OIDC)
resource "aws_lb_target_group" "hydra" {
  name                 = "${var.app_name}-${var.environment}-hydra-public"
  port                 = var.hydra_public_port
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
    path                = "/health/alive"
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
      Name = "${var.app_name}-${var.environment}-hydra-tg"
    }
  )
}

# HTTPS Listener with host-based routing
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.ory.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  # Default: 404 when no host matches
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

# Listener rule: identity.oauthentra.com -> Kratos
resource "aws_lb_listener_rule" "kratos" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kratos.arn
  }

  condition {
    host_header {
      values = [var.kratos_host]
    }
  }
}

# Listener rule: auth.oauthentra.com -> Hydra
resource "aws_lb_listener_rule" "hydra" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 110

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hydra.arn
  }

  condition {
    host_header {
      values = [var.hydra_host]
    }
  }
}

# HTTP Listener (redirects to HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ory.arn
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
