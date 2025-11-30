module "vpc" {
  source = "git::https://github.com/akhilankam/infra-modules.git//vpc"

  region          = var.region
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

module "iam" {
  source = "git::https://github.com/akhilankam/infra-modules.git//iam"

  cluster_name = "my-eks-cluster"
}

module "eks" {
  source = "git::https://github.com/akhilankam/infra-modules.git//eks"

  cluster_name           = "my-eks-cluster"
  eks_cluster_role_arn   = module.iam.eks_cluster_role_arn
  eks_node_role_arn      = module.iam.eks_node_role_arn
  private_subnets        = module.vpc.private_subnets
}

module "rds" {
  source = "git::https://github.com/akhilankam/infra-modules.git//rds"

  vpc_security_group_ids = [module.vpc.database_sg_id]
  subnet_ids             = module.vpc.private_subnets
}

module "alb_ingress" {
  source = "git::https://github.com/akhilankam/infra-modules.git//alb"

  cluster_name              = module.eks.cluster_name
  cluster_oidc_provider_arn = module.eks.oidc_provider_arn
}

