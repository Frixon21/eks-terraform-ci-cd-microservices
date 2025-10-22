variable "cluster_name" {
  type        = string
  description = "Base name used for IAM resources"
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to IAM resources"
}
