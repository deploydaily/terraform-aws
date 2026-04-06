variable "project_name" {
  description = "Project name — used in resource names and tags"
  type        = string
  default     = "awx"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group (min 2)"
  type        = list(string)
}

variable "controller_sg_id" {
  description = "AWX controller security group ID — allowed to reach RDS"
  type        = string
}

variable "db_password" {
  description = "RDS master password — passed in from secrets module"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class — must be t3/t4g micro/small/medium for ACG sandbox"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB — max 50 for ACG sandbox"
  type        = number
  default     = 20
}