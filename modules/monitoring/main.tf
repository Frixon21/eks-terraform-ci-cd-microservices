# modules/monitoring/main.tf
terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}


locals {
  release_name = var.release_name
  ns           = var.namespace
}

# Strong admin password for Grafana
resource "random_password" "grafana_admin" {
  length  = 20
  special = true
}

# Secret consumed by the chart for Grafana admin username/password
resource "kubernetes_secret" "grafana_admin" {
  metadata {
    name      = "${local.release_name}-grafana-admin"
    namespace = local.ns
  }

  type = "Opaque"

  # Use plain strings here; DO NOT base64encode.
  data = {
    admin-user     = "admin"
    admin-password = random_password.grafana_admin.result
  }
}

# kube-prometheus-stack: Prometheus + Alertmanager + Grafana
resource "helm_release" "kps" {
  name       = local.release_name
  namespace  = local.ns
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  # Pin to a recent stable version; adjust as needed
  version    = var.chart_version

  # Keep it lightweight for MVP
  values = [
    yamlencode({
      grafana = {
        admin = {
          existingSecret = kubernetes_secret.grafana_admin.metadata[0].name
          userKey        = "admin-user"
          passwordKey    = "admin-password"
        }
        service = {
          type = "ClusterIP"
          port = 80
        }
      }
      # Keep Prometheus/Alertmanager UIs internal for now (port-forward if needed)
      prometheus = {
        service = { type = "ClusterIP" }
      }
      alertmanager = {
        service = { type = "ClusterIP" }
      }
    })
  ]

  # Make sure namespace exists before Helm runs
  depends_on = [var.namespace_ready_dep]
}

# Expose Grafana via AWS ALB (using your existing ALB Ingress Controller)
resource "kubernetes_ingress_v1" "grafana_alb" {
  metadata {
    name      = "${local.release_name}-grafana-alb"
    namespace = local.ns
    annotations = {
      "kubernetes.io/ingress.class"           = "alb"
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
      "alb.ingress.kubernetes.io/listen-ports" = <<-JSON
        [{"HTTP":80}]
      JSON
    }
  }

  spec {
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              # kube-prometheus-stack exposes Grafana as <release>-grafana on port 80
              name = "${helm_release.kps.name}-grafana"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.kps]
}

output "grafana_admin_user" {
  value       = "admin"
  description = "Grafana admin user"
}

output "grafana_admin_password" {
  value       = random_password.grafana_admin.result
  sensitive   = true
  description = "Grafana admin password"
}
