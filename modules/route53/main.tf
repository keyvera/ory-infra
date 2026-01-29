# Route53 Record for Kratos (e.g., identity.oauthentra.com)
resource "aws_route53_record" "kratos" {
  zone_id = var.hosted_zone_id
  name    = var.kratos_record_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Route53 Record for Hydra (e.g., auth.oauthentra.com)
resource "aws_route53_record" "hydra" {
  count = var.hydra_record_name != "" ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = var.hydra_record_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
