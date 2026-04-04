variable "project_name" {
  description   = "Project Name — used in resource names and subnet tags"
  type          = string
  default       = "nt-infra"
}

variable "region" {
  type    = string
  default = "us-east-1"
}