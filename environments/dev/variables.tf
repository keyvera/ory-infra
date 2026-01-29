variable "app_name" {
  description = "Application name"
  type        = string
  default     = "kratos"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs (for ALB and ECS)"
  type        = list(string)
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

variable "domain" {
  description = "Domain name for the public endpoint"
  type        = string
  default     = "identity.oauthentra.com"
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
  default     = 256  # Cost-optimized for dev
}

variable "memory" {
  description = "Memory for ECS tasks in MB"
  type        = number
  default     = 512  # Cost-optimized for dev
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1  # Cost-optimized for dev
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 7  # Cost-optimized for dev
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to access admin endpoint"
  type        = list(string)
  default     = []
}

variable "access_logs_enabled" {
  description = "Enable ALB access logs"
  type        = bool
  default     = false  # Cost-optimized for dev
}

variable "access_logs_bucket" {
  description = "S3 bucket for ALB access logs"
  type        = string
  default     = ""
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
  description = "List of Secrets Manager secret ARN patterns for IAM (e.g. [\"arn:aws:secretsmanager:us-east-1:ACCOUNT:secret:dev/kratos*\"])"
  type        = list(string)
  default     = []
}
