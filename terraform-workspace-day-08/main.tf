terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

variable "instance_ami" {
  type    = string
  default = "ami-05d2d839d4f73aafb"
}

variable "app_name" {
  type    = string
  default = "snapdeal"
}

# Create SG
resource "aws_security_group" "app_sg" {
  name = "${terraform.workspace}-${var.app_name}-sg"

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
  instance_type   = terraform.workspace == "prod" ? "t3.small" : "t3.micro"
  security_groups = [aws_security_group.app_sg.name]
  tags = {
    Name = "${var.app_name}-instance"
    ENV = "${terraform.workspace}"
  }
}
