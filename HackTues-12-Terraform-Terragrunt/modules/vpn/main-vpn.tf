# resource "aws_security_group" "vpn_sg" {
#   name        = "${var.environment}-${var.app_name}-vpn-sg"
#   description = "Security group for Client VPN endpoint"
#   vpc_id      = var.vpc_id
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   tags = { Name = "${var.environment}-${var.app_name}-vpn-sg" }
# }

# resource "aws_ec2_client_vpn_endpoint" "this" {
#   description            = "${var.environment}-${var.app_name}-client-vpn"
#   server_certificate_arn = var.server_certificate_arn
#   client_cidr_block      = var.client_cidr
#   split_tunnel           = true
#   dns_servers            = ["8.8.8.8", "8.8.4.4"]
#   transport_protocol     = "udp"
#   vpn_port               = 443
#   security_group_ids     = [aws_security_group.vpn_sg.id]
#   authentication_options {
#     type                       = "certificate-authentication"
#     root_certificate_chain_arn = var.client_certificate_arn
#   }
#   connection_log_options { enabled = false }
#   tags = { Name = "${var.environment}-${var.app_name}-client-vpn-endpoint" }
# }

# # Associate with all private subnets
# resource "aws_ec2_client_vpn_network_association" "private" {
#   for_each               = toset(var.private_subnet_ids)
#   client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
#   subnet_id              = each.value
# }

# resource "aws_ec2_client_vpn_route" "to_vpc" {
#   for_each               = aws_ec2_client_vpn_network_association.private
#   client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
#   destination_cidr_block = var.vpc_cidr
#   target_vpc_subnet_id   = each.value.subnet_id
# }

# # Allow VPN SG to reach DocumentDB SG on port
# resource "aws_security_group_rule" "vpn_to_docdb" {
#   type                     = "ingress"
#   description              = "Allow VPN clients to DocumentDB"
#   from_port                = var.docdb_port
#   to_port                  = var.docdb_port
#   protocol                 = "tcp"
#   source_security_group_id = aws_security_group.vpn_sg.id
#   security_group_id        = var.authorization_security_group_id
# }

