# # ACM Module for VPN Certificates

# resource "aws_acm_certificate" "vpn_server" {
#   domain_name       = var.vpn_server_domain
#   validation_method = "DNS"

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = {
#     Name = "${var.environment}-${var.app_name}-vpn-server-cert"
#   }
# }

# resource "aws_acm_certificate" "vpn_client" {
#   domain_name       = var.vpn_client_domain
#   validation_method = "DNS"

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = {
#     Name = "${var.environment}-${var.app_name}-vpn-client-cert"
#   }
# }

# # Auto-validate using Route53

# data "aws_route53_zone" "main" {
#   name         = "${var.environment}.${var.app_name}.${var.main_domain}"
#   private_zone = false
# }

# resource "aws_route53_record" "vpn_server_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.vpn_server.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }
#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = data.aws_route53_zone.main.zone_id
# }

# resource "aws_route53_record" "vpn_client_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.vpn_client.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }
#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = data.aws_route53_zone.main.zone_id
# }

# resource "aws_acm_certificate_validation" "vpn_server" {
#   certificate_arn         = aws_acm_certificate.vpn_server.arn
#   validation_record_fqdns = [for record in aws_route53_record.vpn_server_validation : record.fqdn]

#   depends_on = [aws_route53_record.vpn_server_validation]

#   # timeouts {
#   #   create = "45m"
#   # }
# }

# resource "aws_acm_certificate_validation" "vpn_client" {
#   certificate_arn         = aws_acm_certificate.vpn_client.arn
#   validation_record_fqdns = [for record in aws_route53_record.vpn_client_validation : record.fqdn]

#   depends_on = [aws_route53_record.vpn_client_validation]

#   # timeouts {
#   #   create = "45m"
#   # }
# }
