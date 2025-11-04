# File: modules/eks/variables.tf
variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "cluster_role_arn" {
  type        = string
  description = "IAM role ARN assumed by the EKS control plane"
}

variable "node_role_arn" {
  type        = string
  description = "IAM role ARN assumed by EKS managed node groups"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets for the cluster/nodegroups"
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to AWS resources"
}

variable "node_desired" { type = number }
variable "node_min" { type = number }
variable "node_max" { type = number }

variable "cluster_version" {
  type        = string
  description = "EKS control plane version"
  default     = null
}

variable "instance_types" {
  type        = list(string)
  description = "Instance types for the node group"
  default     = ["t3.large"]
}

variable "apps_labels" {
  type        = map(string)
  description = "Labels applied to the application node group"
  default     = { role = "apps" }
}

variable "addon_resolve_conflicts" {
  type        = string
  description = "Conflict resolution strategy for EKS addons"
  default     = null
}

variable "admin_principal_arn" {
  description = "Optional IAM user/role ARN to grant cluster-admin via EKS Access API. Leave null to skip."
  type        = string
  default     = null
}
