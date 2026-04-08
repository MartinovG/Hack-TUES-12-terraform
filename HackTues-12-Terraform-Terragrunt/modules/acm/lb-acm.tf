// LB ACM certificate
resource "aws_acm_certificate" "server_cert" {
  domain_name       = local.app_fqdn
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

// Server ACM certificate validation

resource "aws_route53_record" "server_cert_validation_records" {
  for_each = {
    for dvo in aws_acm_certificate.server_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true // It allows managing these records in a single Terraform run without the requirement for terraform import.
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300 // change to 172800 in PROD
  type            = each.value.type
  zone_id         = var.hosted_zone_id
}

# There is a default timeout of 45min for the certificate to be issued and validated
resource "aws_acm_certificate_validation" "server_cert_validation" {
  certificate_arn         = aws_acm_certificate.server_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.server_cert_validation_records : record.fqdn]
}
