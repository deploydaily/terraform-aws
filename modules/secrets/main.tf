# ------------------------------------------------------
# Random passwords — generated once, stored in state
# ------------------------------------------------------
resource "random_password" "db" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}?"
}

resource "random_password" "awx_admin" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}?"
}

# ------------------------------------------------------
# awx/db-password
# ------------------------------------------------------
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "awx/db-password"
  description             = "AWX RDS PostgreSQL password"
  recovery_window_in_days = 0

  tags = { Name = "${var.project_name}-db-password" }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db.result
}

# ------------------------------------------------------
# awx/admin-password
# ------------------------------------------------------
resource "aws_secretsmanager_secret" "awx_admin_password" {
  name                    = "awx/admin-password"
  description             = "AWX UI admin password"
  recovery_window_in_days = 0

  tags = { Name = "${var.project_name}-admin-password" }
}

resource "aws_secretsmanager_secret_version" "awx_admin_password" {
  secret_id     = aws_secretsmanager_secret.awx_admin_password.id
  secret_string = random_password.awx_admin.result
}