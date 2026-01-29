variable "app_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of public subnet IDs for ECS tasks (cheapest: public subnets + public IP)"
  type        = list(string)
}

variable "kratos_image" {
  description = "Kratos Docker image"
  type        = string
  default     = "oryd/kratos"
}

variable "kratos_image_tag" {
  description = "Kratos Docker image tag"
  type        = string
  default     = "v25.4.0-distroless"
}

variable "public_port" {
  description = "Public API port"
  type        = number
  default     = 4433
}

variable "admin_port" {
  description = "Admin API port"
  type        = number
  default     = 4434
}

variable "cpu" {
  description = "CPU units for ECS tasks (1024 = 1 vCPU)"
  type        = number
  default     = 512
}

variable "memory" {
  description = "Memory for ECS tasks in MB"
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

variable "ecs_tasks_security_group_id" {
  description = "Security group ID for ECS tasks (public + admin)"
  type        = string
}

variable "public_target_group_arn" {
  description = "Target group ARN for public API"
  type        = string
}

variable "kratos_log_group_name" {
  description = "CloudWatch log group name for Kratos service"
  type        = string
}

variable "kratos_log_group_arn" {
  description = "CloudWatch log group ARN for Kratos service"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "kratos_environment_vars" {
  description = "Environment variables for Kratos containers"
  type        = list(map(string))
  default     = []
}

variable "kratos_secrets" {
  description = "Secrets for Kratos containers (from Secrets Manager or Parameter Store)"
  type        = list(map(string))
  default     = []
}

variable "secrets_manager_secret_arns" {
  description = "List of Secrets Manager secret ARNs (or patterns with *) the task execution role can read. E.g. [\"arn:aws:secretsmanager:region:account:secret:dev/kratos*\"]"
  type        = list(string)
  default     = []
}

variable "s3_config_bucket_name" {
  description = "S3 bucket name for Kratos config files"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ECS task role ARN (created in environment file)"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
