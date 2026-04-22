variable "providers_config" {
  type = map(object({
    region            = string
    vpc_cidr_block    = string
    subnet_cidr_block = string
    vpc_name          = string
    ec2 = object({
      instance_type = string
      key_name = string
    })
  }))

  default = {
    primary = {
      region            = "ap-south-1"
      vpc_cidr_block    = "10.0.0.0/16"
      subnet_cidr_block = "10.0.1.0/24"
      vpc_name          = "primary"
      ec2 = {
        instance_type = "t3.micro"
        key_name = "ap-south-1-key"
      }
    }

    secondary = {
      region            = "ap-south-2"
      vpc_cidr_block    = "10.1.0.0/16"
      subnet_cidr_block = "10.1.1.0/24"
      vpc_name          = "secondary"
      ec2 = {
        instance_type = "t3.micro"
        key_name = "ap-south-2-key"
      }
    }
  }
}
