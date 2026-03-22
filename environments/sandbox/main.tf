module "ec2" {
  source = "../../modules/ec2"

  name             = "sandbox-ec2-basic"
  ami_id           = var.ami_id
  instance_type    = var.instance_type
  subnet_id        = var.subnet_id
  assign_public_ip = var.assign_public_ip

  tags = {
    Project = "terraform-aws"
    Env     = "sandbox"
  }
}