variable "env" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
  
}

variable "vpc_id" {
  description = "VPC ID where the bastion host will be created"
  type        = string
  
}

variable "key_name" {
  description = "SSH key pair name for accessing the bastion host"
  type        = string
  
}

# Add your variable declarations here

variable "public_subnets" {
  description = "The ID of the public subnet where the bastion host will be deployed"
  type        = list(string)
}