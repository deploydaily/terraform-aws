resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.assign_public_ip

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}