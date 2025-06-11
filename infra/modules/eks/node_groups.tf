resource "aws_eks_node_group" "public_node_group" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.env}-public-node-group"
  node_role_arn   = aws_iam_role.nodes.role_arn
  subnet_ids      = var.public_subnets
  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 1
  }
  ami_type       = "AL2_x86_64"
  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"
}

resource "aws_eks_node_group" "private_node_group" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.env}-private-node-group"
  node_role_arn   = aws_iam_role.nodes.role_arn
  subnet_ids      = var.private_subnets
  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 1
  }
  ami_type       = "AL2_x86_64"
  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"
}