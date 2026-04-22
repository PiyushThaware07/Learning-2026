# -----------------------------------------
# Step-01 : Create a VPC
# -----------------------------------------
resource "aws_vpc" "hdrive_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.vpc_name}-vpc"
  }
}

# -----------------------------------------
# Step-02 : Create Internet Gateway
# -----------------------------------------
resource "aws_internet_gateway" "hdrive_igw" {
  vpc_id = aws_vpc.hdrive_vpc.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

# -----------------------------------------
# Step-03 : Public Subnet
# -----------------------------------------
resource "aws_subnet" "hdrive_public_subnet" {
  vpc_id                  = aws_vpc.hdrive_vpc.id
  cidr_block              = var.vpc_public_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_name}-public-subnet"
  }
}

# -----------------------------------------
# Step-04 : Private Subnet
# -----------------------------------------
resource "aws_subnet" "hdrive_private_subnet" {
  vpc_id     = aws_vpc.hdrive_vpc.id
  cidr_block = var.vpc_private_subnet_cidr

  tags = {
    Name = "${var.vpc_name}-private-subnet"
  }
}

# -----------------------------------------
# Step-05 : Public Route Table
# -----------------------------------------
resource "aws_route_table" "hdrive_public_rt" {
  vpc_id = aws_vpc.hdrive_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hdrive_igw.id
  }

  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

# -----------------------------------------
# Step-06 : Private Route Table (NO IGW ROUTE HERE)
# -----------------------------------------
resource "aws_route_table" "hdrive_private_rt" {
  vpc_id = aws_vpc.hdrive_vpc.id

  tags = {
    Name = "${var.vpc_name}-private-rt"
  }
}

# -----------------------------------------
# Step-07 : Route Table Associations
# -----------------------------------------
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.hdrive_public_subnet.id
  route_table_id = aws_route_table.hdrive_public_rt.id
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.hdrive_private_subnet.id
  route_table_id = aws_route_table.hdrive_private_rt.id
}

# -----------------------------------------
# Step-08 : Elastic IP for NAT Gateway
# -----------------------------------------
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.vpc_name}-nat-eip"
  }
}

# -----------------------------------------
# Step-09 : NAT Gateway (in Public Subnet)
# -----------------------------------------
resource "aws_nat_gateway" "hdrive_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.hdrive_public_subnet.id

  depends_on = [aws_internet_gateway.hdrive_igw]

  tags = {
    Name = "${var.vpc_name}-nat-gateway"
  }
}

# -----------------------------------------
# Step-10 : Private Route → NAT Gateway
# -----------------------------------------
resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.hdrive_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.hdrive_nat.id
}