output "kratos_dns_name" {
  description = "FQDN of the Kratos public endpoint"
  value       = aws_route53_record.kratos.fqdn
}

output "hydra_dns_name" {
  description = "FQDN of the Hydra public endpoint (empty if disabled)"
  value       = var.hydra_record_name != "" ? aws_route53_record.hydra[0].fqdn : ""
}
