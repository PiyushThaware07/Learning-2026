variable "providers_config" {
  type = map(object({
    region = string
  }))

  default = {
    primary = {
      region = "ap-south-1"
    }

    secondary = {
      region = "ap-south-2"
    }
  }
}
