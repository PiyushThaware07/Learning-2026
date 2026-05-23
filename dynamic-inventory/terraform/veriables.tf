variable "aws_region" {
  description = "Default aws region"
  type        = string
  default     = "ap-south-1"
}



variable "aws_instances" {
  description = "EC2 instances configuration"

  type = map(object({
    instance_type = string
    ami           = string

    tags = object({
      Name         = string
      os_family    = string
      distribution = string
      user         = string
    })
  }))

  default = {
    control-node-ubuntu = {
      instance_type = "t3.micro"
      ami           = "ami-07a00cf47dbbc844c"
      tags = {
        Name         = "ansible-control-node-ubuntu"
        os_family    = "linux"
        distribution = "ubuntu"
        user         = "ubuntu"
      }
    }

    worker-node-ubuntu = {
      instance_type = "t3.micro"
      ami           = "ami-07a00cf47dbbc844c"
      tags = {
        Name         = "ansible-worker-node-ubuntu"
        os_family    = "linux"
        distribution = "ubuntu"
        user         = "ubuntu"
      }
    }

    # Debian Worker
    worker-node-debian = {
      instance_type = "t3.micro"
      ami = "ami-0ad737a8b58b3fb92"
      tags = {
        Name         = "ansible-worker-node-debian"
        os_family    = "linux"
        distribution = "debian"
        user         = "admin"
      }
    }

    worker-node-amazonlinux = {
      instance_type = "t3.micro"
      ami           = "ami-09ed39e30153c3bf9"

      tags = {
        Name         = "ansible-managed-node-amazonlinux"
        os_family    = "linux"
        distribution = "amazon-linux"
        user         = "ec2-user"
      }
    }
  }
}
