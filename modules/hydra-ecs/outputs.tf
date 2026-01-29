output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.hydra.id
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.hydra.arn
}

output "service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.hydra.name
}

output "admin_endpoint" {
  description = "Hydra admin API endpoint (Service Discovery hostname)"
  value       = "hydra-admin.${aws_service_discovery_private_dns_namespace.hydra.name}:${var.hydra_admin_port}"
}
