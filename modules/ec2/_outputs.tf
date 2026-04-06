output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.awx_controller.id
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.awx_controller.private_ip
}

output "public_ip" {
  description = "Public IP address of the instance"
  value       = aws_instance.awx_controller.public_ip
}

output "security_group_id" {
  description = "Security group ID attached to the instance"
  value       = aws_security_group.awx_controller_sg.id
}

output "key_name" {
  description = "EC2 key pair name"
  value       = aws_key_pair.ec2_key_pair.key_name
}