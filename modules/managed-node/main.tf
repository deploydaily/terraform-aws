resource "aws_key_pair" "windows_key" {
  count      = var.os_type == "windows" ? 1 : 0
  key_name   = "${var.node_name}-key"
  public_key = file(var.windows_public_key_path)
}

resource "aws_instance" "managed_node" {
  ami           = var.os_type == "linux" ? data.aws_ami.al2023.id : data.aws_ami.windows2022.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  key_name      = var.os_type == "windows" ? aws_key_pair.windows_key[0].key_name : var.key_name

  associate_public_ip_address = false

  vpc_security_group_ids = [aws_security_group.managed_node_sg.id]

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.os_type == "windows" ? 50 : 30
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name       = var.node_name
    role       = var.os_type == "windows" ? "windows" : "linux"
    env        = var.env
    managed_by = "awx"
    os_type    = var.os_type
  }
}