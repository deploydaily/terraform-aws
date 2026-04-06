# ------------------------------------------------------
# Create EC2 Keypair using local public key
# ------------------------------------------------------

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "awx-key"
  public_key = file(var.public_key_path)

  tags = {
    Name    = "awx-key"
    Project = "terraform-aws"
    Env     = "dev"
  }
}

# ------------------------------------------------------
# AWX Controller — t3.medium · RHEL 9 · public subnet
# ------------------------------------------------------
resource "aws_instance" "awx_controller" {
  ami                    = data.aws_ami.rhel9.id
  instance_type          = var.instance_type
  subnet_id              = var.ec2_subnet_id
  vpc_security_group_ids = [aws_security_group.awx_controller_sg.id]
  iam_instance_profile   = var.ec2_instance_profile_name
  key_name               = aws_key_pair.ec2_key_pair.key_name

  user_data = templatefile("${path.module}/userdata/awx-controller.sh.tftpl", {
    aws_region      = var.aws_region
    db_host         = var.db_host
    db_name         = var.db_name
    db_user         = var.db_user
    db_secret_name  = var.db_secret_name
    adm_secret_name = var.adm_secret_name
  })

  user_data_replace_on_change = true

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name       = "awx-controller"
    role       = "controller"
    managed_by = "terraform"
  }

  depends_on = [
    aws_key_pair.ec2_key_pair
  ]
}