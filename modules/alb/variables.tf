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

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN"
  type        = string
}

variable "kratos_public_port" {
  description = "Kratos public API port"
  type        = number
  default     = 4433
}

variable "kratos_host" {
  description = "Host header for Kratos routing (e.g., identity.oauthentra.com)"
  type        = string
}

variable "hydra_public_port" {
  description = "Hydra public API port"
  type        = number
  default     = 4444
}

variable "hydra_host" {
  description = "Host header for Hydra routing (e.g., auth.oauthentra.com)"
  type        = string
}

variable "access_logs_bucket" {
  description = "S3 bucket for ALB access logs"
  type        = string
  default     = ""
}

variable "access_logs_enabled" {
  description = "Enable ALB access logs"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
