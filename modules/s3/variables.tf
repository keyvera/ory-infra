variable "app_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "kratos_ecs_task_role_id" {
  description = "Kratos ECS task role ID (name) for S3 config access"
  type        = string
}

variable "hydra_ecs_task_role_id" {
  description = "Hydra ECS task role ID (name) for S3 config access"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
