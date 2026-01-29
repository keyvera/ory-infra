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
