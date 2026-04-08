resource "aws_route53_zone" "app_subdomain" {
  name    = "${var.app_name}.${var.main_domain}"
  comment = "Hosted zone for the ${var.app_name} application subdomain"
}
