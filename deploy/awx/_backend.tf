terraform {
  backend "s3" {
    bucket         = "awx-platform-tf-state-tbd"
    key            = "awx/sandbox/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "awx-platform-tf-locks"
    encrypt        = true
  }
}