output "endpoint" {
  description = "PostgreSQL endpoint"
  value       = aws_db_instance.postgres.address
}

output "instance_id" {
  description = "PostgreSQL instance identifier"
  value       = aws_db_instance.postgres.id
}

output "database_url" {
  description = "PostgreSQL connection string"
  value       = "postgresql://${aws_ssm_parameter.postgres_username.value}:${aws_ssm_parameter.postgres_password.value}@${aws_db_instance.postgres.address}:5432/${aws_ssm_parameter.postgres_database_name.value}"
  sensitive   = true
}
