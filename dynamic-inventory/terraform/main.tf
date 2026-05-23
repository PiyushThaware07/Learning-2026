# Security Group
resource "aws_security_group" "ansible_sg" {
  name        = "ansible_sg"
  description = "Security group for Ansible servers"

  # SSH
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ansible_sg"
  }
}

# EC2 Instance
resource "aws_instance" "ansible_ec2" {
  for_each      = var.aws_instances
  ami           = each.value.ami
  instance_type = each.value.instance_type
  key_name = "aws-key"
  vpc_security_group_ids = [
    aws_security_group.ansible_sg.id
  ]
  tags = {
    Name         = each.value.tags.Name
    os_family    = each.value.tags.os_family
    distribution = each.value.tags.distribution
    user         = each.value.tags.user
  }
}
