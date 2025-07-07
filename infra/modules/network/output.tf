output "vpc_id" {
  description = "The ID of the VPC created for the Flask application."
  value       = aws_vpc.main.id
}

output "aws_subnet_ids" {
  description = "The IDs of the subnets created for the Flask application."
  value       = aws_subnet.public_subnets[*].id
}

output "public_subnets" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public_subnets[*].id
}

output "private_subnets" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private_subnets[*].id
}   


output "aws_internet_gateway_id" {
  description = "The ID of the Internet Gateway created for the Flask application."
  value       = aws_internet_gateway.igw.id
}

output "aws_nat_gateway_ids" {
  description = "The IDs of the NAT Gateways created for the Flask application."
  value       = aws_nat_gateway.nat[*].id
}
