resource "aws_instance" "bastion" {
  ami = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id = var.public_subnets
  key_name = var.key_name

  vpc_security_group_ids = [
    aws_security_group.bastion_sg.id
  ]
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y aws-cli
    sudo yum install -y kubectl jq
    echo "Bastion host setup complete."
    EOF

    tags = {
      Name = "${var.env}-bastion-host"
    }
}

resource "aws_security_group" "bastion_sg" {
  name        = "${var.env}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}

resource "aws_iam_role_policy_attachment" "bastion_eks" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.env}-bastion-profile"
  role = aws_iam_role.bastion.name
}

resource "aws_iam_role" "bastion" {
  name = "${var.env}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}
