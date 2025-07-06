output "security_group_id" {
  description = "ID of the security group for the bastion host"
  value       = aws_security_group.bastion_sg.id
}

output "public_subnets" {
  description = "List of public subnet IDs passed to the bastion module"
  value       = var.public_subnets # Reference the variable instead of a non-existent resource
}