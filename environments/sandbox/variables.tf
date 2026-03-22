variable "ami_id" {
  description = "AMI ID for sandbox EC2"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for sandbox EC2"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for sandbox EC2"
  type        = string
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP"
  type        = bool
  default     = false
}