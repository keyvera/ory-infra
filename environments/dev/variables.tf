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

variable "kratos_domain" {
  description = "Domain for Kratos public endpoint (e.g., identity.oauthentra.com)"
  type        = string
  default     = "identity.oauthentra.com"
}

variable "kratos_image" {
  description = "Kratos Docker image"
  type        = string
  default     = "oryd/kratos"
}

variable "kratos_image_tag" {
  description = "Kratos Docker image tag (use Alpine e.g. v25.4.0 for ECS health checks; distroless lacks wget)"
  type        = string
  default     = "v25.4.0"
}

variable "kratos_public_port" {
  description = "Kratos public API port"
  type        = number
  default     = 4433
}

variable "kratos_admin_port" {
  description = "Kratos admin API port"
  type        = number
  default     = 4434
}

variable "kratos_cpu" {
  description = "CPU units for Kratos ECS tasks (1024 = 1 vCPU)"
  type        = number
  default     = 256  # Cost-optimized for dev
}

variable "kratos_memory" {
  description = "Memory for Kratos ECS tasks in MB"
  type        = number
  default     = 512  # Cost-optimized for dev
}

variable "kratos_desired_count" {
  description = "Desired number of Kratos tasks"
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

variable "kratos_secrets_manager_secret_arns" {
  description = "List of Secrets Manager secret ARN patterns for Kratos IAM"
  type        = list(string)
  default     = []
}

# ACM: Add auth.oauthentra.com for Hydra
variable "acm_subject_alternative_names" {
  description = "Additional domains for ACM certificate (e.g., auth.oauthentra.com for Hydra)"
  type        = list(string)
  default     = ["auth.oauthentra.com"]
}

# Route53: Add auth.oauthentra.com record

# Hydra configuration
variable "hydra_domain" {
  description = "Domain for Hydra public endpoint"
  type        = string
  default     = "auth.oauthentra.com"
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

variable "hydra_image" {
  description = "Hydra Docker image"
  type        = string
  default     = "oryd/hydra"
}

variable "hydra_image_tag" {
  description = "Hydra Docker image tag (use Alpine e.g. v25.4.0 for ECS health checks; distroless lacks wget)"
  type        = string
  default     = "v25.4.0"
}

variable "hydra_cpu" {
  description = "CPU units for Hydra ECS tasks"
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
  description = "List of Secrets Manager secret ARN patterns for Hydra IAM"
  type        = list(string)
  default     = []
}

variable "hydra_s3_config_key" {
  description = "S3 object key for Hydra config (shared bucket)"
  type        = string
  default     = "hydra-config.yaml"
}
