output "vpc_id" {
  description = "VPC ID — passed into EKS module"
  value       = aws_vpc.main_vpc.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [
    aws_subnet.public_subnet_one.id,
    aws_subnet.public_subnet_two.id
  ]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [
    aws_subnet.private_subnet_one.id,
    aws_subnet.private_subnet_two.id
  ]
}

output "vpc_cidr_block" {
  description = "VPC CIDR — useful for security group ingress rules"
  value       = aws_vpc.main_vpc.cidr_block
}