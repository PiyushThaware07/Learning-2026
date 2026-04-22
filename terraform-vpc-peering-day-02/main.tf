# CREATED PRIMARY VPC
resource "aws_vpc" "primary_vpc" {
  provider             = aws.primary
  cidr_block           = var.providers_config["primary"].vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.providers_config["primary"].vpc_name}-vpc-${var.providers_config["primary"].region}"
  }
}

# CREATED SECONDARY VPC
resource "aws_vpc" "secondary_vpc" {
  provider             = aws.secondary
  cidr_block           = var.providers_config["secondary"].vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.providers_config["secondary"].vpc_name}-vpc-${var.providers_config["secondary"].region}"
  }
}


# CREATED SUBNET FOR PRIMARY-VPC
resource "aws_subnet" "primary_subnet" {
  provider                = aws.primary
  vpc_id                  = aws_vpc.primary_vpc.id
  cidr_block              = var.providers_config["primary"].subnet_cidr_block
  availability_zone       = data.aws_availability_zones.primary_azs.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.providers_config["primary"].vpc_name}-Subnet-${var.providers_config["primary"].region}"
    ENV  = "Dev"
  }
}


# CREATED SUBNET FOR SECONDARY-VPC
resource "aws_subnet" "secondary_subnet" {
  provider                = aws.secondary
  vpc_id                  = aws_vpc.secondary_vpc.id
  cidr_block              = var.providers_config["secondary"].subnet_cidr_block
  availability_zone       = data.aws_availability_zones.secondary_azs.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.providers_config["secondary"].vpc_name}-Subnet-${var.providers_config["secondary"].region}"
    ENV  = "Dev"
  }
}


# CREATE INTERNET GATEWAY FOR PRIMARY-VPC
resource "aws_internet_gateway" "primary_igw" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary_vpc.id
  tags = {
    Name = "${var.providers_config["primary"].vpc_name}-IGW-${var.providers_config["primary"].region}"
    ENV  = "Dev"
  }
}

# CREATE INTERNET GATEWAY FOR SECONDARY-VPC
resource "aws_internet_gateway" "secondary_igw" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary_vpc.id
  tags = {
    Name = "${var.providers_config["secondary"].vpc_name}-IGW-${var.providers_config["secondary"].region}"
    ENV  = "Dev"
  }
}

# CREATE ROUTE TABLE FOR PRIMARY-VPC
resource "aws_route_table" "primary_rt" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.primary_igw.id
  }
  tags = {
    Name = "${var.providers_config["primary"].vpc_name}-RT-${var.providers_config["primary"].region}"
    ENV  = "Dev"
  }
}

# CREATE ROUTE TABLE FOR SECONDARY-VPC
resource "aws_route_table" "secondary_rt" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.secondary_igw.id
  }
  tags = {
    Name = "${var.providers_config["secondary"].vpc_name}-RT-${var.providers_config["secondary"].region}"
    ENV  = "Dev"
  }
}


# Associate route table with subnet in PRIMARY-VPC
resource "aws_route_table_association" "primary_rta" {
  provider       = aws.primary
  subnet_id      = aws_subnet.primary_subnet.id
  route_table_id = aws_route_table.primary_rt.id
}

# Associate route table with subnet in SECONDARY-VPC
resource "aws_route_table_association" "secondary_rta" {
  provider       = aws.secondary
  subnet_id      = aws_subnet.secondary_subnet.id
  route_table_id = aws_route_table.secondary_rt.id
}

# Create VPC peering connection from PRIMARY VPC to SECONDARY VPC (cross-region)
resource "aws_vpc_peering_connection" "primary_to_secondary" {
  provider    = aws.primary
  vpc_id      = aws_vpc.primary_vpc.id
  peer_vpc_id = aws_vpc.secondary_vpc.id
  peer_region = var.providers_config["secondary"].region
  auto_accept = false
  tags = {
    Name = "${var.providers_config["primary"].vpc_name}-to-${var.providers_config["secondary"].vpc_name}-peering"
    ENV  = "Dev"
    Type = "Requester"
  }
}

# Accept VPC peering connection on SECONDARY VPC side
resource "aws_vpc_peering_connection_accepter" "secondary_accept" {
  provider                  = aws.secondary
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id
  auto_accept               = true
  tags = {
    Name = "${var.providers_config["secondary"].vpc_name}-accept-peering"
    ENV  = "Dev"
    Type = "Accepter"
  }
}

# Add route in PRIMARY VPC route table to send traffic to SECONDARY VPC via peering connection
resource "aws_route" "primary_to_secondary" {
  provider                  = aws.primary
  route_table_id            = aws_route_table.primary_rt.id
  destination_cidr_block    = var.providers_config["secondary"].vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id
  depends_on                = [aws_vpc_peering_connection_accepter.secondary_accept]
}

# Add route in SECONDARY VPC route table to send traffic to PRIMARY VPC via peering connection
resource "aws_route" "secondary_to_primary" {
  provider                  = aws.secondary
  route_table_id            = aws_route_table.secondary_rt.id
  destination_cidr_block    = var.providers_config["primary"].vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id
  depends_on                = [aws_vpc_peering_connection_accepter.secondary_accept]
}

# Security group for PRIMARY VPC
resource "aws_security_group" "primary_sg" {
  provider    = aws.primary
  vpc_id      = aws_vpc.primary_vpc.id
  name        = "${var.providers_config["primary"].vpc_name}-vpc-sg"
  description = "security group for ${var.providers_config["primary"].vpc_name} vpc instance"

  ingress {
    description = "SSH From Anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP From Secondary-VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.providers_config["secondary"].vpc_cidr_block]
  }

  ingress {
    description = "All traffic from Secondary VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.providers_config["secondary"].vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.providers_config["primary"].vpc_name}-sg"
    ENV  = "Dev"
  }
}


# Security group for SECONDARY VPC
resource "aws_security_group" "secondary_sg" {
  provider    = aws.secondary
  vpc_id      = aws_vpc.secondary_vpc.id
  name        = "${var.providers_config["secondary"].vpc_name}-vpc-sg"
  description = "security group for ${var.providers_config["secondary"].vpc_name} vpc instance"

  ingress {
    description = "SSH From Anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP From Primary-VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.providers_config["primary"].vpc_cidr_block]
  }

  ingress {
    description = "All traffic from Primary VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.providers_config["primary"].vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.providers_config["secondary"].vpc_name}-sg"
    ENV  = "Dev"
  }
}

# CREATED EC2 INSTANCE FOR PRIMARY VPC
resource "aws_instance" "primary_ec2_instance" {
  provider               = aws.primary
  ami                    = data.aws_ami.primary_ami.id
  instance_type          = var.providers_config["primary"].ec2.instance_type
  subnet_id              = aws_subnet.primary_subnet.id
  vpc_security_group_ids = [aws_security_group.primary_sg.id]
  key_name               = var.providers_config["primary"].ec2.key_name
  user_data              = local.primary_user_data
  tags = {
    Name = "${var.providers_config["primary"].vpc_name}-ec2-instance"
    ENV  = "Dev"
    Region = var.providers_config["primary"].region
  }
  depends_on = [ aws_vpc_peering_connection_accepter.secondary_accept ]
}

# CREATED EC2 INSTANCE FOR SECONDARY VPC
resource "aws_instance" "secondary_ec2_instance" {
  provider               = aws.secondary
  ami                    = data.aws_ami.secondary_ami.id
  instance_type          = var.providers_config["secondary"].ec2.instance_type
  subnet_id              = aws_subnet.secondary_subnet.id
  vpc_security_group_ids = [aws_security_group.secondary_sg.id]
  key_name               = var.providers_config["secondary"].ec2.key_name
  user_data              = local.secondary_user_data
  tags = {
    Name = "${var.providers_config["secondary"].vpc_name}-ec2-instance"
    ENV  = "Dev"
    Region = var.providers_config["secondary"].region
  }
  depends_on = [ aws_vpc_peering_connection_accepter.secondary_accept ]
}
