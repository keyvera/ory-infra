output "public_dns_name" {
  description = "DNS name of the public endpoint"
  value       = aws_route53_record.public.fqdn
}
