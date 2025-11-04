# Pull cluster outputs from the dev (infra) state
locals {
  common_tags = {
    Project = "capstone"
    Owner   = "alex"
    Env     = "dev"
  }
}

data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket       = "alex-capstone-tfstate"
    key          = "envs/dev/eks.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "aws" {
  region  = var.region
  profile = "ubuntu"
  default_tags {
    tags = local.common_tags
  }
}

# Use the remote state values for providers
data "aws_eks_cluster_auth" "this" {
  name = data.terraform_remote_state.infra.outputs.cluster_name
}


provider "kubernetes" {
  host                   = data.terraform_remote_state.infra.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.infra.outputs.cluster_ca)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes = {
    host                   = data.terraform_remote_state.infra.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.infra.outputs.cluster_ca)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

# Namespaces live in the addons layer now
resource "kubernetes_namespace" "platform" {
  metadata { name = var.namespace }
}

resource "kubernetes_namespace" "dev" {
  metadata { name = "dev" }
}


# addons module now belongs here (unchanged inputs, but sourced from remote state)
module "addons" {
  source = "../../modules/addons"

  cluster_name      = data.terraform_remote_state.infra.outputs.cluster_name
  region            = var.region
  vpc_id            = data.terraform_remote_state.infra.outputs.vpc_id
  oidc_provider_arn = data.terraform_remote_state.infra.outputs.oidc_provider_arn
  oidc_issuer_url   = data.terraform_remote_state.infra.outputs.oidc_issuer
  namespace         = var.namespace
  tags              = local.common_tags

  depends_on = [
    kubernetes_namespace.platform
  ]
}

module "monitoring" {
  source = "../../modules/monitoring"

  namespace            = var.namespace       # "platform"
  release_name         = "kps"
  chart_version        = "58.3.2"
  namespace_ready_dep  = kubernetes_namespace.platform

  depends_on = [
    module.addons      # ensure ALB controller is up before creating Ingress
  ]
}