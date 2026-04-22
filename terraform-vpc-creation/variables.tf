variable "vpc_name" {
    type = string
    default = "hdrive"
}

variable "vpc_cidr" {
    type = string
    default = "10.0.0.0/16"
}

variable "vpc_public_subnet_cidr" {
    type = string
    default = "10.0.1.0/24"
}

variable "vpc_private_subnet_cidr" {
    type = string
    default = "10.0.2.0/24"
}

variable "ec2_ami_id" {
    type = string
    default = "ami-05d2d839d4f73aafb"
}

variable "ec2_type" {
    type = string
    default = "t3.micro"
}