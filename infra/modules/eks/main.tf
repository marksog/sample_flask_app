module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.env}-devsecops-cluster"
  cluster_version = "1.28"
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids

  enable_irsa = true

  eks_managed_node_groups = {}

}
resource "aws_eks_node_group" "public_node_group" {
  cluster_name    = module.eks.cluster_name
  node_group_name = "${var.env}-public-node-group"
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = var.public_subnets

  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 1
  }

  ami_type       = "AL2_x86_64"
  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"
  disk_size      = 20

  labels = {
    nodegroup   = "public"
    environment = var.env
  }

  taint {
    key    = "public"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  remote_access {
    ec2_ssh_key = var.key_name
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }

  depends_on = [module.eks]
}

    resource "aws_eks_node_group" "private_node_group" {
        cluster_name    = var.cluster_name
        node_group_name = "${var.env}-private-node-group"
        node_role_arn   = aws_iam_role.nodes.arn
        subnet_ids      = var.private_subnets
        scaling_config {
        desired_size = 1
        max_size     = 3
        min_size     = 1
        }
        ami_type         = "AL2_x86_64"
        instance_types   = ["t3.medium"]
        capacity_type    = "ON_DEMAND"
        disk_size        = 20
    
        labels = {
        nodegroup   = "private"
        environment = var.env
        }
    
        remote_access {
        ec2_ssh_key = var.key_name
        }
    
        lifecycle {
        create_before_destroy = true
        ignore_changes        = [scaling_config[0].desired_size]
        }
    
        depends_on = [module.eks]
    }

resource "aws_iam_role" "nodes" {
  name = "${var.env}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.env}-eks-node-role"
  }
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}