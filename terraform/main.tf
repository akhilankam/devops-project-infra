provider "aws" {
  region = var.region
}

module "vpc" {
  source = "git::https://github.com/akhilankam/infra-modules.git//vpc"

  region          = var.region
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}
