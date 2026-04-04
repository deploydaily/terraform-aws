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