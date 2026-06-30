output "cluster_role_arn" {
  description = "ARN of the EKS cluster role"
  value       = aws_iam_role.cluster.arn
}

output "node_group_role_arn" {
  description = "ARN of the node group role"
  value       = aws_iam_role.node_group.arn
}

output "vpc_cni_role_arn" {
  description = "ARN of the VPC CNI role (IRSA)"
  value       = var.enable_irsa ? aws_iam_role.vpc_cni[0].arn : ""
}

output "fargate_role_arns" {
  description = "ARNs of the Fargate profile roles"
  value       = { for k, v in aws_iam_role.fargate : k => v.arn }
}

output "autoscaler_role_arn" {
  description = "ARN of the cluster autoscaler role (IRSA)"
  value       = var.enable_autoscaler ? aws_iam_role.autoscaler[0].arn : ""
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = var.enable_irsa ? aws_iam_openid_connect_provider.eks[0].arn : ""
}

output "oidc_provider_url" {
  description = "OIDC provider URL"
  value       = var.oidc_provider_url
}
