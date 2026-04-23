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

module "dev_app" {
  source        = "./modules/web_app"
  app_name      = "dev_snapdeal"
  instance_ami  = "ami-05d2d839d4f73aafb"
  instance_type = "t3.micro"
}

module "prod_app" {
  source        = "./modules/web_app"
  app_name      = "prod_snapdeal"
  instance_ami  = "ami-05d2d839d4f73aafb"
  instance_type = "t3.small"
}