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