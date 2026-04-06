# ------------------------------------------------------
# sg-rds — PostgreSQL from AWX controller SG only
# ------------------------------------------------------
resource "aws_security_group" "rds_sg" {
  name_prefix = "awx-rds-"
  description = "RDS PostgreSQL inbound from AWX controller only"
  vpc_id      = var.vpc_id

  tags = { Name = "sg-awx-rds" }

  lifecycle { create_before_destroy = true }
}

resource "aws_vpc_security_group_ingress_rule" "rds_postgres" {
  security_group_id            = aws_security_group.rds_sg.id
  description                  = "PostgreSQL from AWX controller SG"
  referenced_security_group_id = var.controller_sg_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}