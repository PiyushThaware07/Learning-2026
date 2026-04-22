terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# ---------- Provider ----------
provider "aws" {
  region = "ap-south-1"
}
