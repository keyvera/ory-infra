output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.kratos.id
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.kratos.arn
}

output "kratos_task_definition_arn" {
  description = "Task definition ARN for Kratos service"
  value       = aws_ecs_task_definition.kratos.arn
}

output "kratos_service_id" {
  description = "ECS service ID for Kratos"
  value       = aws_ecs_service.kratos.id
}

output "kratos_admin_endpoint" {
  description = "Admin API endpoint (private DNS, VPC-only). Use https://kratos-admin.<namespace>:4434"
  value       = "kratos-admin.${aws_service_discovery_private_dns_namespace.kratos.name}"
}
