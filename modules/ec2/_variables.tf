variable "ec2_instance_profile_name" {
  description = "EC2 instance profile name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ec2_subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_key_path" {
  description = "Path to local public key file"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "db_host" {
  description = "RDS endpoint"
  type        = string
}

variable "db_name" {
  description = "RDS database name"
  type        = string
  default     = "awx"
}

variable "db_user" {
  description = "RDS master username"
  type        = string
  default     = "awx"
}

variable "db_secret_name" {
  description = "Secrets Manager secret name for DB password"
  type        = string
}

variable "adm_secret_name" {
  description = "Secrets Manager secret name for AWX admin password"
  type        = string
}

variable "controller_ip" {
  description = "AWX controller public IP — written to bootstrap log"
  type        = string
  default     = ""
}