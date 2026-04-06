# ------------------------------------------------------
# DB Subnet Group — needs two private subnets (two AZs)
# ------------------------------------------------------
resource "aws_db_subnet_group" "awx" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = { Name = "${var.project_name}-db-subnet-group" }
}

# ------------------------------------------------------
# RDS PostgreSQL 15 — single-AZ, ACG sandbox safe
# ------------------------------------------------------
resource "aws_db_instance" "awx" {
  identifier        = "${var.project_name}-postgres"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp2"        # ACG sandbox: no provisioned IOPS
  storage_encrypted = true

  db_name  = "awx"
  username = "awx"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.awx.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible     = false
  multi_az                = false  # sandbox — ADR-004
  skip_final_snapshot     = true   # sandbox only
  deletion_protection     = false
  backup_retention_period = 0      # sandbox only

  tags = { Name = "${var.project_name}-postgres" }
}