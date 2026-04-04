# ------------------------------------------------------
# Get Public IP and add it to SG inbound rules
# ------------------------------------------------------

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  my_ip_cidr = "${chomp(data.http.my_ip.response_body)}/32"
}

# ------------------------------------------------------
# sg-awx-controller
# ------------------------------------------------------
resource "aws_security_group" "awx_controller_sg" {
  name_prefix = "awx-controller-"
  description = "AWX controller HTTPS SSH from admin IP"
  vpc_id      = var.vpc_id

  tags = { Name = "sg-awx-controller" }

  lifecycle { create_before_destroy = true }
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.awx_controller_sg.id
  description       = "HTTPS from admin IP"
  cidr_ipv4         = local.my_ip_cidr
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.awx_controller_sg.id
  description       = "SSH from admin IP"
  cidr_ipv4         = local.my_ip_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all_out" {
  security_group_id = aws_security_group.awx_controller_sg.id
  description       = "All outbound"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
