data "aws_ami" "ubuntu" {
  most_recent = true

  # Canonical’s official account in the commercial AWS partition
  owners = ["099720109477"]  

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

data "http" "my_ip" {
  url = "http://checkip.amazonaws.com/"
}

resource "aws_instance" "jenkins" {
  ami =  data.aws_ami.ubuntu.id
  instance_type = "t3.large"
  subnet_id = var.private_subnets[0]  # putting jenins server in private subnet
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  key_name = var.key_name
  iam_instance_profile = aws_iam_instance_profile.jenkins.name

  user_data = templatefile("${path.module}/user_data.sh", {
    cluster_name = var.cluster_name
    region       = var.region
  })

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
  }
tags = {
    Name = "${var.env}-jenkins"
    Environment = var.env
  } 
  depends_on = [var.nat_gateway_id]
}


resource "aws_security_group" "jenkins" {
  name        = "${var.env}-jenkins-sg"
  description = "Security group for Jenkins controller"
  vpc_id      = var.vpc_id
  
  # allow HTTP traffice from ALB to Jenkins
  ingress {
    description = "HTTP from ALB"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.alb.id] # Replace with ALB's subnet CIDR or trusted IP range
    
  }

  ingress {
    description = "SSH from bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [var.bastion_sg_id]
  }

  ingress {
    description = "Kubernetes API access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # Restrict to your VPC CIDR
  }
  
  # Allow return traffic from VPC endpoints
ingress {
  description = "Allow HTTPS responses from VPC endpoints"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = [var.vpc_cidr]
}
  # Allow all outbound traffic from Jenkins server
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-jenkins-sg"
  }
}


# secuity group for ALB
resource "aws_security_group" "alb" {
  name        = "${var.env}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  # Allow HTTP traffic from the internet to ALB
  ingress {
    description = "Allow HTTP traffic from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to the internet
  }

  # Allow all outbound traffic from ALB
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-alb-sg"
  }
}


resource "aws_iam_role" "jenkins" {
  name = "${var.env}-jenkins-role"

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

resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.env}-jenkins-profile"
  role = aws_iam_role.jenkins.name
}

resource "aws_iam_role_policy_attachment" "jenkins_eks" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "jenkins_ssm" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "jenkins_custom" {
  name = "${var.env}-jenkins-custom-policy"
  role = aws_iam_role.jenkins.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi",
          "sts:AssumeRole"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ec2:Describe*",
          "iam:ListRoles"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:*"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::${var.env}-jenkins-artifacts",
          "arn:aws:s3:::${var.env}-jenkins-artifacts/*"
        ]
      }
    ]
  })
}

# resource "aws_route53_record" "jenkins" {
#   count   = var.create_dns_record ? 1 : 0
#   zone_id = var.route53_zone_id
#   name    = "jenkins.${var.domain_name}"
#   type    = "A"
#   ttl     = 300
#   records = [aws_instance.jenkins.public_ip]
# }

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

# Application Load Balancer (ALB)
resource "aws_lb" "jenkins_alb" {
  name               = "jenkins-alb-${var.env}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnets
  tags = {
    Name        = "jenkins-alb-${var.env}"
    Environment = var.env
  }
}

# ALB Listener
resource "aws_lb_listener" "jenkins_listener" {
  load_balancer_arn = aws_lb.jenkins_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.jenkins_target_group.arn
  }
}

resource "aws_lb_target_group" "jenkins_target_group" {
  name        = "jenkins-tg-${var.env}"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"
  health_check {
    path                = "/login" # Jenkins login page 
    interval            = 30       # Health check every 30 seconds
    timeout             = 5        # Timeout for health check response
    healthy_threshold  = 2         # Number of consecutive successful checks before marking as healthy
    unhealthy_threshold = 2        # Number of consecutive failed checks before marking as unhealthy
  }
}

resource "aws_lb_target_group_attachment" "jenkins_attachment" {
  target_group_arn = aws_lb_target_group.jenkins_target_group.arn
  target_id        = aws_instance.jenkins.id
  port             = 8080
}
