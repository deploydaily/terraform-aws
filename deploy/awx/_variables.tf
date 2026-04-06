variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name — used in resource tags"
  type        = string
  default     = "awx"
}

variable "instance_type" {
  description = "EC2 instance type for AWX controller"
  type        = string
  default     = "t3.medium"
}

variable "public_key_path" {
  description = "Path to local SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}