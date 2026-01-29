output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.public.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB"
  value       = aws_lb.public.zone_id
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = aws_lb.public.arn
}

output "target_group_arn" {
  description = "ARN of the public API target group"
  value       = aws_lb_target_group.public.arn
}

# Backwards compatibility aliases
output "public_alb_dns_name" {
  description = "DNS name of the ALB (alias)"
  value       = aws_lb.public.dns_name
}

output "public_alb_zone_id" {
  description = "Zone ID of the ALB (alias)"
  value       = aws_lb.public.zone_id
}

output "public_alb_arn" {
  description = "ARN of the ALB (alias)"
  value       = aws_lb.public.arn
}

output "public_target_group_arn" {
  description = "ARN of the public API target group (alias)"
  value       = aws_lb_target_group.public.arn
}
