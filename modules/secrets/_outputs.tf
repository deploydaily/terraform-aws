output "db_password" {
  description = "RDS password — passed directly into RDS module"
  value       = random_password.db.result
  sensitive   = true
}

output "db_secret_name" {
  description = "Secrets Manager secret name for DB password"
  value       = aws_secretsmanager_secret.db_password.name
}

output "db_secret_arn" {
  description = "Secrets Manager secret ARN for DB password"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "admin_secret_name" {
  description = "Secrets Manager secret name for AWX admin password"
  value       = aws_secretsmanager_secret.awx_admin_password.name
}

output "admin_secret_arn" {
  description = "Secrets Manager secret ARN for AWX admin password"
  value       = aws_secretsmanager_secret.awx_admin_password.arn
}