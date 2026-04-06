variable "node_name" {
  description = "Name tag for the managed node"
  type        = string
}

variable "os_type" {
  description = "OS type - linux or windows"
  type        = string
  validation {
    condition     = contains(["linux", "windows"], var.os_type)
    error_message = "os_type must be linux or windows."
  }
}

variable "env" {
  description = "Environment tag - dev or prod"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID to launch the node in"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "controller_sg_id" {
  description = "AWX controller SG ID - granted inbound access"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}

variable "windows_public_key_path" {
  description = "Path to RSA public key for Windows node (ED25519 not supported)"
  type        = string
  default     = ""
}