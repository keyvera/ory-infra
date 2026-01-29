output "alb_security_group_id" {
  description = "Security group ID for ALB"
  value       = aws_security_group.alb_public.id
}

output "alb_public_security_group_id" {
  description = "Security group ID for ALB (alias for backwards compatibility)"
  value       = aws_security_group.alb_public.id
}

output "ecs_tasks_security_group_id" {
  description = "Security group ID for ECS tasks (Kratos)"
  value       = aws_security_group.ecs_tasks.id
}
