terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
module "network" {
    source = "./modules/network"
    env    = var.env
    vpc_cidr = var.vpc_cidr
}

module "eks" {
    source         = "./modules/eks"
    env            = var.env
    vpc_id         = module.network.vpc_id
    subnet_ids     = concat(module.network.public_subnets, module.network.private_subnets)
    key_name       = var.key_name
    private_subnets = module.network.private_subnets
    public_subnets  = module.network.public_subnets
    cluster_name   = var.cluster_name
}

module "bastion" {
    source         = "./modules/bastion"
    env            = var.env
    vpc_id         = module.network.vpc_id
    public_subnets = module.network.public_subnets
    key_name       = var.key_name
}


module "jenkins" {
  source         = "./modules/jenkins"
  env            = var.env
  vpc_id         = module.network.vpc_id
  public_subnets = module.network.private_subnets # alliginging with indus standards
  key_name       = var.key_name
  cluster_name   = module.eks.cluster_name
  bastion_sg_id  = module.bastion.security_group_id
  vpc_cidr      = var.vpc_cidr # Pass vpc_cidr to the Jenkins module
}

resource "aws_security_group_rule" "allow_jenkins_to_eks" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = module.eks.eks_cluster_security_group_id # EKS cluster security group
  source_security_group_id = module.jenkins.security_group_id         # Jenkins security group
}

resource "aws_security_group_rule" "jenkins_to_eks" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = module.jenkins.security_group_id         # Jenkins security group
  cidr_blocks = ["0.0.0.0/0"]  # EKS cluster security group
}