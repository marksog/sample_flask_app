variable "env" {
  description = "Environment name (dev/prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Jenkins will be deployed"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block of the VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bastion_sg_id" {
  description = "Bastion security group ID for SSH access"
  type        = string
}

variable "create_dns_record" {
  description = "Whether to create Route53 record"
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "Route53 zone ID for DNS record"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for Jenkins"
  type        = string
  default     = "example.com"
}
