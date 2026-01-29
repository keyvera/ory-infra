output "public_endpoint" {
  description = "Public endpoint URL"
  value       = "https://${var.domain}"
}

output "public_alb_dns_name" {
  description = "Public ALB DNS name"
  value       = module.load_balancer.public_alb_dns_name
}

output "admin_endpoint" {
  description = "Admin API endpoint (private DNS, VPC-only). Use https://<endpoint>:4434"
  value       = module.ecs.kratos_admin_endpoint
}

output "ecs_cluster_id" {
  description = "ECS cluster ID"
  value       = module.ecs.cluster_id
}

output "ecs_service_name" {
  description = "ECS service name for Kratos"
  value       = module.ecs.kratos_service_id
}

output "kratos_log_group_name" {
  description = "CloudWatch log group name for Kratos"
  value       = module.cloudwatch.kratos_log_group_name
}

output "s3_config_bucket_name" {
  description = "S3 bucket name for Kratos config"
  value       = module.s3.bucket_name
}

output "ecs_security_group_ids" {
  description = "ECS security group IDs (for migration task network config)"
  value       = [module.security_groups.ecs_tasks_security_group_id]
}

output "ecs_task_role_arn" {
  description = "ECS task role ARN"
  value       = aws_iam_role.ecs_task.arn
}
