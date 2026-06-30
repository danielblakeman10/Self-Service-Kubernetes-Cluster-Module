# EKS Module outputs

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded CA certificate"
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.this.name
}

output "cluster_security_group_id" {
  description = "Security group for the cluster"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group for nodes"
  value       = local.node_security_group_id
}

output "oidc_provider_url" {
  description = "OIDC provider URL"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "node_groups" {
  description = "EKS node group names"
  value       = { for k, v in aws_eks_node_group.this : k => v.node_group_arn }
}
