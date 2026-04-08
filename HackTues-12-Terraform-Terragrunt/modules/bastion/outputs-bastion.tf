output "bastion_instance_id" {
  description = "ID of the bastion EC2 instance"
  value       = aws_instance.private_bastion.id
}

output "bastion_private_ip" {
  description = "Private IP address of the bastion instance"
  value       = aws_instance.private_bastion.private_ip
}

output "bastion_iam_role_arn" {
  description = "IAM role ARN for the bastion instance"
  value       = aws_iam_role.bastion_private_role.arn
}
