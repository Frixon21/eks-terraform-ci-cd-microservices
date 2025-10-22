# File: envs/dev/variables.tf

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "microservices-demo"
}

variable "apps_node_desired" {
  description = "Desired node count for the application node group"
  type        = number
  default     = 2
}

variable "apps_node_min" {
  description = "Minimum node count for the application node group"
  type        = number
  default     = 1
}

variable "apps_node_max" {
  description = "Maximum node count for the application node group"
  type        = number
  default     = 4
}

variable "apps_instance_types" {
  description = "Instance types for the application node group"
  type        = list(string)
  default     = ["t3.large"]
}

// System node group variables removed for MVP
