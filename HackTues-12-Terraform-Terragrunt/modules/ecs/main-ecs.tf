// Obtaining secrets from the Secrets Manager
data "aws_secretsmanager_secret" "VITE_GOOGLE_API_KEY" {
  name = "VITE_GOOGLE_API_KEY"
}
data "aws_secretsmanager_secret_version" "VITE_GOOGLE_API_KEY" {
  secret_id = data.aws_secretsmanager_secret.VITE_GOOGLE_API_KEY.id
}
