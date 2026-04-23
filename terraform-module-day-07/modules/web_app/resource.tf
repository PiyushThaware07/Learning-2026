# Create SG
resource "aws_security_group" "app_sg" {
  name = "${var.app_name}-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create EC2 Instance
resource "aws_instance" "app_instance" {
  ami             = var.instance_ami
  instance_type   = var.instance_type
  security_groups = [aws_security_group.app_sg.name]
  tags = {
    Name = "${var.app_name}-instance"
  }
}
