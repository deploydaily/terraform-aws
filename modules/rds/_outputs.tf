output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint — passed into AWX bootstrap"
  value       = aws_db_instance.awx.address
}

output "rds_port" {
  description = "RDS PostgreSQL port"
  value       = aws_db_instance.awx.port
}

output "rds_db_name" {
  description = "RDS database name"
  value       = aws_db_instance.awx.db_name
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds_sg.id
}