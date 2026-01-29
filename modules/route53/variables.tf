variable "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

variable "domain" {
  description = "Domain name for the public endpoint"
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

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
