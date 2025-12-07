variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type = map(string)
  default = {
    "10.0.1.0/24" = "ap-south-1a"
    "10.0.2.0/24" = "ap-south-1b"
  }
}

variable "private_subnets" {
  type = map(string)
  default = {
    "10.0.3.0/24" = "ap-south-1a"
    "10.0.4.0/24" = "ap-south-1b"
  }
}
