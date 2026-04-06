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