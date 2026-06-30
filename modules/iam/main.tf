# IAM Module - EKS cluster roles, node group roles, IRSA, and Fargate

# ========================================
# EKS Cluster Role
# ========================================

resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-cluster-role"
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

# ========================================
# Node Group Role
# ========================================

resource "aws_iam_role" "node_group" {
  name = "${var.cluster_name}-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-node-group-role"
  })
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

# ========================================
# VPC CNI IAM Role (IRSA)
# ========================================

resource "aws_iam_role" "vpc_cni" {
  count = var.enable_irsa ? 1 : 0

  name = "${var.cluster_name}-vpc-cni-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_url, "https://", "")}:sub": "system:serviceaccount:kube-system:aws-node"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-vpc-cni-role"
  })
}

resource "aws_iam_role_policy_attachment" "vpc_cni_AmazonEKS_CNI_Policy" {
  count      = var.enable_irsa ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni[0].name
}

# ========================================
# Fargate Profile Roles
# ========================================

resource "aws_iam_role" "fargate" {
  for_each = { for k, v in var.fargate_profiles : k => v }

  name = "${var.cluster_name}-${each.key}-fargate-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${each.key}-fargate-role"
  })
}

resource "aws_iam_role_policy_attachment" "fargate_AmazonEKSPodExecutionRolePolicy" {
  for_each   = { for k, v in var.fargate_profiles : k => v }
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSPodExecutionRolePolicy"
  role       = aws_iam_role.fargate[each.key].name
}

# ========================================
# Cluster Autoscaler IAM Role (IRSA)
# ========================================

resource "aws_iam_role" "autoscaler" {
  count = var.enable_autoscaler ? 1 : 0

  name = "${var.cluster_name}-autoscaler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_url, "https://", "")}:aud": "sts.amazonaws.com"
          }
          StringLike = {
            "${replace(var.oidc_provider_url, "https://", "")}:sub": "system:serviceaccount:kube-system:cluster-autoscaler"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-autoscaler-role"
  })
}

resource "aws_iam_role_policy_attachment" "autoscaler_AmazonEKSManagedNodeClusterPolicy" {
  count      = var.enable_autoscaler ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSManagedNodeClusterPolicy"
  role       = aws_iam_role.autoscaler[0].name
}

resource "aws_iam_role_policy_attachment" "autoscaler_AutoScalingFullAccess" {
  count      = var.enable_autoscaler ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
  role       = aws_iam_role.autoscaler[0].name
}

# ========================================
# OIDC Provider (for IRSA)
# ========================================

data "tls_certificate" "eks" {
  url = var.oidc_provider_url
}

resource "aws_iam_openid_connect_provider" "eks" {
  count = var.enable_irsa ? 1 : 0

  url             = var.oidc_provider_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]

  tags = merge(var.tags, var.oidc_provider_tags, {
    Name = "${var.cluster_name}-oidc-provider"
  })
}

# ========================================
# Variables
# ========================================

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "enable_irsa" {
  description = "Enable IRSA"
  type        = bool
  default     = true
}

variable "enable_autoscaler" {
  description = "Deploy cluster autoscaler"
  type        = bool
  default     = true
}

variable "enable_fargate" {
  description = "Enable Fargate profiles"
  type        = bool
  default     = false
}

variable "fargate_profiles" {
  description = "Fargate profile configurations"
  type = map(object({
    name         = string
    subnet_ids   = list(string)
    namespace_labels = optional(map(string), {})
    tags         = optional(map(string), {})
  }))
  default = {}
}

variable "oidc_provider_url" {
  description = "OIDC provider URL from EKS cluster"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "oidc_provider_tags" {
  description = "Tags for the OIDC provider"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

# ========================================
# Outputs
# ========================================

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
