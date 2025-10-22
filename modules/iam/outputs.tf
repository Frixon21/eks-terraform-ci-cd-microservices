output "cluster_role_arn" {
  value = aws_iam_role.eks_cluster.arn
}

output "node_role_arn" {
  value = aws_iam_role.eks_node.arn
}

output "cluster_role_name" {
  value = aws_iam_role.eks_cluster.name
}

output "node_role_name" {
  value = aws_iam_role.eks_node.name
}
