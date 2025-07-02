output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = var.cluster_name
}

output "eks_cluster_security_group_id" {
  description = "The security group ID for the EKS cluster"
  value       = aws_security_group.eks_cluster.id
}