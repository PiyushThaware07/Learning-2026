output "vpc_id" {
  value = aws_vpc.hdrive_vpc.id
}

output "vpc_public_subnet_id" {
  value = aws_subnet.hdrive_public_subnet.id
}

output "vpc_private_subnet_id" {
  value = aws_subnet.hdrive_private_subnet.id
}

output "vpc_igw" {
  value = aws_internet_gateway.hdrive_igw.id
}
