# Public EC2 Security Group
resource "aws_security_group" "public_ec2_sg" {
  name   = "${var.vpc_name}-public-ec2-sg"
  vpc_id = aws_vpc.hdrive_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-public-ec2-sg"
  }
}

# Private EC2 Security Group (only from VPC)
resource "aws_security_group" "private_ec2_sg" {
  name   = "${var.vpc_name}-private-ec2-sg"
  vpc_id = aws_vpc.hdrive_vpc.id

  ingress {
    description = "Allow traffic from VPC only"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-private-ec2-sg"
  }
}

# Public EC2 Instance
resource "aws_instance" "public_ec2" {
  ami                         = var.ec2_ami_id
  instance_type               = var.ec2_type
  subnet_id                   = aws_subnet.hdrive_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.public_ec2_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "${var.vpc_name}-public-ec2"
  }
}

# Private EC2 Instance (NO public IP)
resource "aws_instance" "private_ec2" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_type
  subnet_id              = aws_subnet.hdrive_private_subnet.id
  vpc_security_group_ids = [aws_security_group.private_ec2_sg.id]

  # IMPORTANT: no public IP
  associate_public_ip_address = false

  tags = {
    Name = "${var.vpc_name}-private-ec2"
  }
}
