###############################################################################
# enterprise-awx-platform · project/awx/main.tf
###############################################################################

# ------------------------------------------------------
# VPC
# ------------------------------------------------------
module "vpc" {
  source       = "../../modules/vpc"
  project_name = var.project_name
  region       = var.aws_region
}

# ------------------------------------------------------
# IAM
# ------------------------------------------------------
module "iam" {
  source = "../../modules/iam"
}

# ------------------------------------------------------
# EC2 — AWX Controller
# ------------------------------------------------------
module "ec2" {
  source = "../../modules/ec2"

  vpc_id                    = module.vpc.vpc_id
  ec2_subnet_id             = module.vpc.public_subnet_ids[0]
  ec2_instance_profile_name = module.iam.instance_profile_name
  instance_type             = var.instance_type
  public_key_path           = var.public_key_path

  # AWX bootstrap
  aws_region      = var.aws_region
  db_host         = module.rds.rds_endpoint
  db_name         = "awx"
  db_user         = "awx"
  db_secret_name  = module.secrets.db_secret_name
  adm_secret_name = module.secrets.admin_secret_name
  controller_ip   = ""
}

# ------------------------------------------------------
# Managed Nodes
# ------------------------------------------------------
module "linux_node_01" {
  source = "../../modules/managed-node"

  node_name        = "linux-node-01"
  os_type          = "linux"
  env              = "dev"
  instance_type    = "t3.micro"
  subnet_id        = module.vpc.public_subnet_ids[0]
  vpc_id           = module.vpc.vpc_id
  controller_sg_id = module.ec2.security_group_id
  key_name         = module.ec2.key_name
}

module "linux_node_02" {
  source = "../../modules/managed-node"

  node_name        = "linux-node-02"
  os_type          = "linux"
  env              = "prod"
  instance_type    = "t3.micro"
  subnet_id        = module.vpc.public_subnet_ids[1]
  vpc_id           = module.vpc.vpc_id
  controller_sg_id = module.ec2.security_group_id
  key_name         = module.ec2.key_name
}

module "windows_node_01" {
  source = "../../modules/managed-node"

  node_name               = "windows-node-01"
  os_type                 = "windows"
  env                     = "dev"
  instance_type           = "t3.micro"
  subnet_id               = module.vpc.public_subnet_ids[0]
  vpc_id                  = module.vpc.vpc_id
  controller_sg_id        = module.ec2.security_group_id
  key_name                = module.ec2.key_name
  windows_public_key_path = "~/.ssh/awx_windows_rsa.pub"
}

# ------------------------------------------------------
# Secrets Manager
# ------------------------------------------------------
module "secrets" {
  source       = "../../modules/secrets"
  project_name = var.project_name
}

# ------------------------------------------------------
# RDS — PostgreSQL 15
# ------------------------------------------------------
module "rds" {
  source = "../../modules/rds"

  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  controller_sg_id   = module.ec2.security_group_id
  db_password        = module.secrets.db_password
  db_instance_class  = var.db_instance_class
}