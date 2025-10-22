# File: envs/dev/main.tf
# Providers live here (backend already set in backend.tf)
locals {
  common_tags = {
    Project = "capstone"
    Owner   = "alex"
    Env     = "dev"
  }
}

provider "aws" {
  region  = var.region
  profile = "ubuntu"
  default_tags {
    tags = local.common_tags
  }
}

module "network" {
  source = "../../modules/network"
}

module "iam" {
  source       = "../../modules/iam"
  cluster_name = var.cluster_name
  tags         = local.common_tags
}

module "eks" {
  source           = "../../modules/eks"
  cluster_name     = var.cluster_name
  cluster_role_arn = module.iam.cluster_role_arn
  node_role_arn    = module.iam.node_role_arn
  subnet_ids       = module.network.public_subnet_ids
  tags             = local.common_tags

  # Pass module inputs (do not declare variables inside module blocks)
  node_desired = var.apps_node_desired
  node_min     = var.apps_node_min
  node_max     = var.apps_node_max

  instance_types          = var.apps_instance_types
  addon_resolve_conflicts = "OVERWRITE"

  depends_on = [module.iam]
}

// ECR omitted: using upstream public images for microservices-demo (no private registry needed)

output "cluster_name" { value = module.eks.cluster_name }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "cluster_ca" { value = module.eks.cluster_ca }
output "oidc_provider_arn" { value = module.eks.oidc_provider_arn }
output "oidc_issuer" { value = module.eks.oidc_issuer }
output "vpc_id" {
  value = module.network.vpc_id
}
