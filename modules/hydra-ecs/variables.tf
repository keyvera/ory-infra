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
  description = "List of public subnet IDs for ECS tasks"
  type        = list(string)
}

variable "hydra_image" {
  description = "Hydra Docker image"
  type        = string
  default     = "oryd/hydra"
}

variable "hydra_image_tag" {
  description = "Hydra Docker image tag"
  type        = string
  default     = "v25.4.0"  # Alpine (has wget for ECS health checks; distroless lacks shell/wget)
}

variable "hydra_public_port" {
  description = "Hydra public API port (OAuth2/OIDC)"
  type        = number
  default     = 4444
}

variable "hydra_admin_port" {
  description = "Hydra admin API port"
  type        = number
  default     = 4445
}

variable "hydra_cpu" {
  description = "CPU units for Hydra ECS tasks (1024 = 1 vCPU)"
  type        = number
  default     = 256
}

variable "hydra_memory" {
  description = "Memory for Hydra ECS tasks in MB"
  type        = number
  default     = 512
}

variable "hydra_desired_count" {
  description = "Desired number of Hydra tasks"
  type        = number
  default     = 1
}

variable "hydra_ecs_tasks_security_group_id" {
  description = "Security group ID for Hydra ECS tasks"
  type        = string
}

variable "hydra_target_group_arn" {
  description = "Target group ARN for Hydra public API"
  type        = string
}

variable "hydra_log_group_name" {
  description = "CloudWatch log group name for Hydra service"
  type        = string
}

variable "hydra_log_group_arn" {
  description = "CloudWatch log group ARN for Hydra service"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "hydra_environment_vars" {
  description = "Environment variables for Hydra containers"
  type        = list(map(string))
  default     = []
}

variable "hydra_secrets" {
  description = "Secrets for Hydra containers (from Secrets Manager)"
  type        = list(map(string))
  default     = []
}

variable "hydra_secrets_manager_secret_arns" {
  description = "List of Secrets Manager secret ARNs the Hydra task execution role can read"
  type        = list(string)
  default     = []
}

variable "hydra_s3_config_bucket_name" {
  description = "S3 bucket name for Hydra config (shared with Kratos)"
  type        = string
}

variable "hydra_s3_config_key" {
  description = "S3 object key for Hydra config (e.g., hydra-config.yaml)"
  type        = string
  default     = "hydra-config.yaml"
}

variable "hydra_ecs_task_role_arn" {
  description = "Hydra ECS task role ARN"
  type        = string
}

variable "use_fargate_spot" {
  description = "Use Fargate Spot for cost savings"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
