# File: modules/eks/main.tf
locals {
  node_group_common_tags = var.tags
}

# ----- EKS CLUSTER -----
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids = var.subnet_ids
  }
  version = var.cluster_version

  tags = merge(var.tags, {
    "eks.io/cluster-name" = var.cluster_name
  })
}

# ----- NODE GROUPS -----
resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-workers"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.node_desired
    min_size     = var.node_min
    max_size     = var.node_max
  }

  labels = var.apps_labels

  instance_types = var.instance_types

  tags = merge(local.node_group_common_tags, {
    "eks.io/node-group" = "apps"
  })

  depends_on = [aws_eks_cluster.this]
}

// Single node group (apps) for MVP

# ----- CORE ADDONS (match your current state) -----
# VPC CNI (AWS manages versioning well)
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = var.addon_resolve_conflicts
  resolve_conflicts_on_update = var.addon_resolve_conflicts
  depends_on                  = [aws_eks_node_group.workers]
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = var.addon_resolve_conflicts
  resolve_conflicts_on_update = var.addon_resolve_conflicts
  depends_on                  = [aws_eks_node_group.workers]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = var.addon_resolve_conflicts
  resolve_conflicts_on_update = var.addon_resolve_conflicts
  depends_on                  = [aws_eks_node_group.workers]
}

# You had metrics_server and pod_identity_agent in state as well:
resource "aws_eks_addon" "metrics_server" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "metrics-server"
  resolve_conflicts_on_create = var.addon_resolve_conflicts
  resolve_conflicts_on_update = var.addon_resolve_conflicts
  depends_on                  = [aws_eks_node_group.workers]
}

// Pod Identity Agent removed for MVP

# --- IRSA / OIDC provider (enable after first apply) ---
data "tls_certificate" "oidc_thumbprint" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc_thumbprint.certificates[0].sha1_fingerprint]
}

# Example IRSA policy attachments live in modules/addons
