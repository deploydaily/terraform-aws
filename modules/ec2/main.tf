locals {
  ingress_rules_expanded = flatten([
    for rule in var.ingress_rules : [
      for cidr in rule.cidr_blocks : {
        description = rule.description
        from_port   = rule.from_port
        to_port     = rule.to_port
        protocol    = rule.protocol
        cidr_block  = cidr
      }
    ]
  ])
}

locals {
  user_data_rendered = (
    var.user_data != null ? var.user_data :
    var.os_type == "amazon_linux" ? file("${path.module}/scripts/ansible_amazon_linux.sh") :
    var.os_type == "rhel" ? file("${path.module}/scripts/ansible_rhel.sh") :
    var.os_type == "ubuntu" ? file("${path.module}/scripts/ansible_ubuntu.sh") :
    null
  )
}

resource "aws_security_group" "this" {
  name_prefix = "${var.name}-sg-"
  description = "Security group for ${var.name}"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-sg"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = {
    for idx, rule in local.ingress_rules_expanded : idx => rule
  }

  security_group_id = aws_security_group.this.id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.protocol
  cidr_ipv4         = each.value.cidr_block
}

resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.this.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.assign_public_ip
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.this.id]
  user_data                   = local.user_data_rendered
  user_data_replace_on_change = true
  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}