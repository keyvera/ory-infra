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

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
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

variable "hydra_public_port" {
  description = "Hydra public API port"
  type        = number
  default     = 4444
}

variable "hydra_admin_port" {
  description = "Hydra admin API port"
  type        = number
  default     = 4445
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to access admin endpoint"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
