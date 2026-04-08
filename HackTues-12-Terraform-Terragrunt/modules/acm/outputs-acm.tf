output "certificate_arn" { value = aws_acm_certificate.server_cert.arn }
output "zone_id" { value = var.hosted_zone_id }
