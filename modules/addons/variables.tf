# File: modules/addons/variables.tf

variable "cluster_name" {
  type = string
}

variable "region" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_issuer_url" {
  type = string
}

variable "namespace" {
  type    = string
  default = "platform"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID used by the ALB controller"
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to AWS resources created by the module"
  default     = {}
}
