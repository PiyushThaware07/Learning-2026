# Fetches an available Availability Zone in the PRIMARY region
data "aws_availability_zones" "primary_azs" {
  provider = aws.primary
  state    = "available"
}

# Fetches an available Availability Zone in the SECONDARY region
data "aws_availability_zones" "secondary_azs" {
  provider = aws.secondary
  state    = "available"
}

# Fetch latest UBUNTU AMIs in PRIMARY region
data "aws_ami" "primary_ami" {
  provider    = aws.primary
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

# Fetch latest UBUNTU AMIs in SECONDARY region
data "aws_ami" "secondary_ami" {
  provider    = aws.secondary
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}