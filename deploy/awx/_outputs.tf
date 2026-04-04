output "controller_public_ip" {
  description = "AWX controller public IP"
  value       = module.ec2.public_ip
}

output "controller_instance_id" {
  description = "AWX controller instance ID"
  value       = module.ec2.instance_id
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "ssh_command" {
  description = "SSH into the AWX controller"
  value       = "ssh -i ~/.ssh/id_ed25519 ec2-user@${module.ec2.public_ip}"
}