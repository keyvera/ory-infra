output "alb_security_group_id" {
  description = "Security group ID for ALB"
  value       = aws_security_group.alb.id
}

output "alb_public_security_group_id" {
  description = "Security group ID for ALB (alias for backwards compatibility)"
  value       = aws_security_group.alb.id
}

output "kratos_ecs_tasks_security_group_id" {
  description = "Security group ID for Kratos ECS tasks"
  value       = aws_security_group.ecs_tasks_kratos.id
}

# Backwards compatibility alias
output "ecs_tasks_security_group_id" {
  description = "Security group ID for Kratos ECS tasks (alias)"
  value       = aws_security_group.ecs_tasks_kratos.id
}

output "hydra_ecs_tasks_security_group_id" {
  description = "Security group ID for Hydra ECS tasks"
  value       = aws_security_group.ecs_tasks_hydra.id
}
