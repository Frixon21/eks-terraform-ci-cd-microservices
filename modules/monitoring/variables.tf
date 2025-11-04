# modules/monitoring/variables.tf
variable "namespace" {
  type        = string
  description = "Namespace to deploy monitoring stack into (use 'platform')"
  default     = "platform"
}

variable "release_name" {
  type        = string
  description = "Helm release name for kube-prometheus-stack"
  default     = "kps"
}

variable "chart_version" {
  type        = string
  description = "Helm chart version for kube-prometheus-stack"
  # Example pinned version; update when you need newer dashboards/features
  default     = "58.3.2"
}

# This lets the module wait for the namespace resource in your envs/addons layer
variable "namespace_ready_dep" {
  description = "Optional dependency to ensure namespace exists before Helm"
  default     = null
}
