variable "cluster_name" {
    description = "Name of the EKS cluster"
    type        = string
  
}

variable "env" {
    description = "Environment name (e.g., dev, staging, prod)"
    type        = string
    default     = "dev"
}

variable "public_subnets" {
    description = "List of public subnet IDs for the EKS cluster"
    type        = list(string)
}

variable "private_subnets" {
    description = "List of private subnet IDs for the EKS cluster"
    type        = list(string)
}

variable "key_name" {
    description = "SSH key pair name for accessing the EKS nodes"
    type        = string  
}

variable "vpc_id" {
    description = "VPC ID where the EKS cluster will be created"
    type        = string
  
}

variable "subnet_ids" {
    description = "List of subnet IDs for the EKS cluster"
    type        = list(string)
}