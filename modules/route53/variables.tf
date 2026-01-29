variable "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

variable "kratos_record_name" {
  description = "Route53 record name for Kratos (subdomain, e.g., identity for identity.oauthentra.com)"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB"
  type        = string
}

variable "alb_zone_id" {
  description = "Zone ID of the ALB"
  type        = string
}

variable "hydra_record_name" {
  description = "Route53 record name for Hydra (subdomain, e.g., auth for auth.oauthentra.com). Empty string to disable."
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
