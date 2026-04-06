# ------------------------------------------------------
# sg-managed-node
# Inbound from AWX controller SG only
# ------------------------------------------------------
resource "aws_security_group" "managed_node_sg" {
  name_prefix = "awx-managed-node-"
  description = "Managed node inbound from AWX controller only"
  vpc_id      = var.vpc_id

  tags = { Name = "sg-${var.node_name}" }

  lifecycle { create_before_destroy = true }
}

# SSH — Linux nodes
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  count = var.os_type == "linux" ? 1 : 0

  security_group_id            = aws_security_group.managed_node_sg.id
  description                  = "SSH from AWX controller"
  referenced_security_group_id = var.controller_sg_id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
}

# WinRM HTTP — Windows nodes
resource "aws_vpc_security_group_ingress_rule" "winrm_http" {
  count = var.os_type == "windows" ? 1 : 0

  security_group_id            = aws_security_group.managed_node_sg.id
  description                  = "WinRM HTTP from AWX controller"
  referenced_security_group_id = var.controller_sg_id
  from_port                    = 5985
  to_port                      = 5985
  ip_protocol                  = "tcp"
}

# WinRM HTTPS — Windows nodes
resource "aws_vpc_security_group_ingress_rule" "winrm_https" {
  count = var.os_type == "windows" ? 1 : 0

  security_group_id            = aws_security_group.managed_node_sg.id
  description                  = "WinRM HTTPS from AWX controller"
  referenced_security_group_id = var.controller_sg_id
  from_port                    = 5986
  to_port                      = 5986
  ip_protocol                  = "tcp"
}

# Outbound — all (needed for dnf/yum + WinRM setup)
resource "aws_vpc_security_group_egress_rule" "all_out" {
  security_group_id = aws_security_group.managed_node_sg.id
  description       = "All outbound"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}