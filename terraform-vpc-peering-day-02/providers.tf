terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.providers_config["primary"].region
  alias = "primary"
}

provider "aws" {
  region = var.providers_config["secondary"].region
  alias = "secondary"
}