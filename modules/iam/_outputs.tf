output "role_name" {
  description = "IAM role name"
  value       = aws_iam_role.awx_controller_role.name
}

output "instance_profile_name" {
  description = "IAM instance profile name"
  value       = aws_iam_instance_profile.awx_controller_instance_profile.name
}

output "instance_profile_arn" {
  description = "IAM instance profile ARN"
  value       = aws_iam_instance_profile.awx_controller_instance_profile.arn
}