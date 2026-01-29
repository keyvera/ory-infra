output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.ory.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB"
  value       = aws_lb.ory.zone_id
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = aws_lb.ory.arn
}

output "kratos_target_group_arn" {
  description = "ARN of the Kratos public API target group"
  value       = aws_lb_target_group.kratos.arn
}

output "hydra_target_group_arn" {
  description = "ARN of the Hydra public API target group"
  value       = aws_lb_target_group.hydra.arn
}

# Backwards compatibility aliases
output "public_alb_dns_name" {
  description = "DNS name of the ALB (alias)"
  value       = aws_lb.ory.dns_name
}

output "public_alb_zone_id" {
  description = "Zone ID of the ALB (alias)"
  value       = aws_lb.ory.zone_id
}

output "public_alb_arn" {
  description = "ARN of the ALB (alias)"
  value       = aws_lb.ory.arn
}

output "public_target_group_arn" {
  description = "ARN of the Kratos public API target group (alias for backwards compatibility)"
  value       = aws_lb_target_group.kratos.arn
}
