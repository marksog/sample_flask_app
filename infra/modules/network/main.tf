resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.env}-vpc"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
resource "aws_subnet" "public_subnets" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.env}-public-subnet-${count.index + 1}"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "private_subnets" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 10)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "${var.env}-private-subnet-${count.index}"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.env}-igw"
  }
}
resource "aws_eip" "nat" {
  count = length(aws_subnet.public_subnets)
  associate_with_private_ip = null
  tags = {
    Name = "${var.env}-nat-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "nat" {
  count = length(aws_subnet.public_subnets)
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id = element(aws_subnet.public_subnets.*.id, count.index)
  tags = {
    Name = "${var.env}-nat-gateway-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.env}-public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public_subnets)
  subnet_id = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
    count = length(aws_subnet.private_subnets)
    vpc_id = aws_vpc.main.id
    route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index % length(aws_nat_gateway.nat)].id
    }
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private_subnets)
  subnet_id = element(aws_subnet.private_subnets.*.id, count.index)
  route_table_id = aws_route_table.private[count.index].id
}

