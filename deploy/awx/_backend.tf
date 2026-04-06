terraform {
  backend "s3" {
    bucket         = "awx-platform-tf-state-557797816042"
    key            = "deploy/awx/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "awx-platform-tf-locks"
    encrypt        = true
  }
}