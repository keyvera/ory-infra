output "kratos_log_group_name" {
  description = "CloudWatch log group name for Kratos service"
  value       = aws_cloudwatch_log_group.kratos.name
}

output "kratos_log_group_arn" {
  description = "CloudWatch log group ARN for Kratos service"
  value       = aws_cloudwatch_log_group.kratos.arn
}

