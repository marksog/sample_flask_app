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
  source  = "./modules/eks"
  env     = var.env

  # Networking
  vpc_id           = module.network.vpc_id
  subnet_ids       = concat(module.network.public_subnets, module.network.private_subnets)
  private_subnets  = module.network.private_subnets
  public_subnets   = module.network.public_subnets

  # Access
  cluster_name                       = var.cluster_name
  key_name                           = var.key_name

  # Optional: add a list of CIDRs allowed to access public endpoint (if you set public access to true)
  # cluster_endpoint_public_access_cidrs = ["YOUR_IP/32"]
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
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
  private_subnets = module.network.private_subnets # using private subnets for Jenkins, alliginging with indus standards
  public_subnets  = module.network.public_subnets # Pass public_subnets to the Jenkins module
  key_name       = var.key_name
  cluster_name   = module.eks.cluster_name
  bastion_sg_id  = module.bastion.security_group_id
  vpc_cidr      = var.vpc_cidr # Pass vpc_cidr to the Jenkins module
  nat_gateway_id = module.network.aws_nat_gateway_ids[0] # Pass NAT gateway ID to Jenkins module
  depends_on = [ module.network ]
}

resource "aws_vpc_endpoint" "eks" {
  vpc_id       = module.network.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.eks"
  vpc_endpoint_type = "Interface"
  subnet_ids   = module.network.private_subnets
  security_group_ids = [aws_security_group.vpce_sg.id] # Allow Jenkins to access
  private_dns_enabled = true
  depends_on = [ module.network, module.eks ]

  tags = {
    Name = "${var.env}-eks-endpoint"
  }
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id = module.network.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.sts"
  vpc_endpoint_type = "Interface"
  subnet_ids = module.network.private_subnets
  security_group_ids = [module.jenkins.security_group_id] # Consistent with eks endpoint
  private_dns_enabled = true

  tags = {
    Name = "${var.env}-sts-endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id = module.network.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type = "Interface"
  subnet_ids = module.network.private_subnets
  security_group_ids = [module.jenkins.security_group_id] # Security group for Jenkins server
  private_dns_enabled = true
  
  tags = {
    Name = "${var.env}-ec2-endpoint"
  }

  
}

resource "aws_security_group_rule" "allow_jenkins_to_eks" {
  description              = "Allow Jenkins to access EKS API"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = module.eks.eks_cluster_security_group_id # EKS cluster security group
  source_security_group_id = module.jenkins.security_group_id         # Jenkins security group
}

resource "aws_security_group_rule" "jenkins_to_eks" {
  description              = "Allow Jenkins to connect to EKS API"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = module.jenkins.security_group_id         # Jenkins security group
  source_security_group_id = module.eks.eks_cluster_security_group_id                                                                    #cidr_blocks = [var.vpc_cidr]  # EKS cluster security group
}

# Additional rule to ensure VPC endpoint communication
resource "aws_security_group_rule" "jenkins_allow_vpc_endpoints" {
  description       = "Allow Jenkins to access VPC endpoints"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = module.jenkins.security_group_id
  cidr_blocks      = [var.vpc_cidr]  # Allow access to all VPC resources
}

resource "aws_security_group_rule" "allow_vpce_to_eks" {
  description       = "Allow VPC Endpoint to EKS API"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = module.eks.eks_cluster_security_group_id
  cidr_blocks      = [var.vpc_cidr]  # Or source_security_group_id if using a custom SG for VPCE
}


resource "aws_security_group" "vpce_sg" {
  vpc_id = module.network.vpc_id

  ingress {
    from_port                = 443
    to_port                  = 443
    protocol                 = "tcp"
    # cidr_blocks = [var.vpc_cidr] # Allow access from the VPC CIDR
    security_groups = [module.jenkins.security_group_id] # Allow inbound traffic from Jenkins security group
  }

  egress  {
    from_port = 433
    to_port   = 443
    protocol  = "tcp"
    security_groups = [module.jenkins.security_group_id] # Allow outbound traffic to Jenkins security group
  }

  tags = {
    Name = "${var.env}-vpce-sg"
  }
}

