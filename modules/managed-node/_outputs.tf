output "instance_id" {
  description = "Managed node instance ID"
  value       = aws_instance.managed_node.id
}

output "private_ip" {
  description = "Managed node private IP - used by AWX inventory"
  value       = aws_instance.managed_node.private_ip
}

output "security_group_id" {
  description = "Managed node security group ID"
  value       = aws_security_group.managed_node_sg.id
}