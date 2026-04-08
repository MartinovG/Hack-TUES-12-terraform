output "zone_id" {
  description = "Route53 hosted zone id for the app subdomain"
  value       = aws_route53_zone.app_subdomain.zone_id
}

output "zone_name" {
  description = "Route53 hosted zone name for the app subdomain"
  value       = trimsuffix(aws_route53_zone.app_subdomain.name, ".")
}

output "name_servers" {
  description = "Name servers to delegate from the parent zone"
  value       = aws_route53_zone.app_subdomain.name_servers
}
