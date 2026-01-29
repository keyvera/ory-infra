# CloudWatch Log Group for Kratos (single service: public + admin APIs)
resource "aws_cloudwatch_log_group" "kratos" {
  name              = "/ecs/${var.app_name}-${var.environment}-kratos"
  retention_in_days  = var.log_retention_days

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-${var.environment}-kratos-logs"
    }
  )
}

# CloudWatch Log Group for Hydra (public + admin APIs)
resource "aws_cloudwatch_log_group" "hydra" {
  name              = "/ecs/${var.app_name}-${var.environment}-hydra"
  retention_in_days  = var.log_retention_days

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-${var.environment}-hydra-logs"
    }
  )
}
