# File: modules/addons/helm.tf

resource "kubernetes_service_account" "alb" {
  metadata {
    name        = "aws-load-balancer-controller"
    namespace   = var.namespace
    annotations = { "eks.amazonaws.com/role-arn" = aws_iam_role.alb.arn }
    labels      = { "app.kubernetes.io/name" = "aws-load-balancer-controller" }
  }
}

resource "helm_release" "alb" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  namespace        = var.namespace
  create_namespace = false
  wait             = true

  set = [
    {
      name  = "region"
      value = var.region
    },
    {
      name  = "clusterName"
      value = var.cluster_name
    },
    {
      name  = "vpcId"
      value = var.vpc_id
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = kubernetes_service_account.alb.metadata[0].name
    }
  ]
  depends_on = [
    kubernetes_service_account.alb
  ]
}


// Cluster Autoscaler removed for MVP
