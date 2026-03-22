resource "aws_key_pair" "this" {
  key_name   = "sandbox-key"
  public_key = file(var.public_key_path)

  tags = {
    Name    = "sandbox-key"
    Project = "terraform-aws"
    Env     = "sandbox"
  }
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  my_ip_cidr = "${chomp(data.http.my_ip.response_body)}/32"
}

module "ec2" {
  source = "../../modules/ec2"

  name             = "sandbox-ec2-basic"
  ami_id           = var.ami_id
  instance_type    = var.instance_type
  subnet_id        = var.subnet_id
  vpc_id           = var.vpc_id
  assign_public_ip = var.assign_public_ip

  key_name         = aws_key_pair.this.key_name

  ingress_rules = [
    {
      description = "SSH from my current public IP"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [local.my_ip_cidr]
    }
  ]

  tags = {
    Project = "terraform-aws"
    Env     = "sandbox"
  }
}