output "eks_cluster_name" {
    value = module.eks.cluster_name
}

# output "security_group_id" {
#   description = "The security group ID for the Jenkins server"
#   value       = aws_security_group.jenkins.id
# }