# EKS Cluster Module - Managed EKS cluster with node groups and addons

locals {
  node_security_group_id = var.cluster_security_group_id
}

# ========================================
# EKS Cluster
# ========================================

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = module.iam.cluster_role_arn

  enabled_cluster_log_types = var.log_types

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = [var.cluster_security_group_id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  dynamic "encryption_config" {
    for_each = var.cluster_encryption_config
    content {
      provider {
        key_arn = encryption_config.value.provider_key_arn
      }
      resources = ["secrets"]
    }
  }

  tags = merge(var.tags, {
    Name = var.cluster_name
  })

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
  ]
}

# ========================================
# Cluster IAM Roles & Policies
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
# EKS Addons
# ========================================

resource "aws_eks_addon" "vpc_cni" {
  cluster_name      = var.cluster_name
  addon_name        = "vpc-cni"
  addon_version     = var.vpc_cni_version == "latest" ? null : var.vpc_cni_version
  service_account_role_arn = var.enable_irsa ? module.iam.vpc_cni_role_arn : null

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}

resource "aws_eks_addon" "coredns" {
  cluster_name      = var.cluster_name
  addon_name        = "coredns"
  addon_version     = var.coredns_version == "latest" ? null : var.coredns_version

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = var.cluster_name
  addon_name        = "kube-proxy"
  addon_version     = var.kube_proxy_version == "" ? null : var.kube_proxy_version

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}

# ========================================
# EKS Managed Node Groups
# ========================================

resource "aws_eks_node_group" "this" {
  for_each = var.eks_managed_node_groups

  cluster_name    = var.cluster_name
  node_group_name = each.key
  node_role_arn   = module.iam.node_group_role_arn
  subnet_ids      = each.value.subnets != null ? each.value.subnets : var.subnet_ids
  instance_types  = each.value.instance_types
  capacity_type   = each.value.capacity_type

  scaling_config {
    min_size     = each.value.min_size
    max_size     = each.value.max_size
    desired_size = each.value.desired_size
  }

  ami_type       = each.value.ami_type
  disk_size      = each.value.disk_size
  ami_release_version = each.value.ami_release_version

  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.key
      value  = taint.value
      effect = "NO_SCHEDULE"
    }
  }

  labels = merge({
    "eks.amazonaws.com/nodegroup" = each.key
    "eks.amazonaws.com/nodegroup-image" = each.value.ami_type
  }, each.value.labels)

  tags = merge(var.tags, each.value.tags, {
    Name = "${var.cluster_name}-${each.key}"
  })

  depends_on = [
    aws_eks_addon.vpc_cni,
    aws_eks_addon.coredns,
    aws_eks_addon.kube_proxy,
  ]
}

# ========================================
# Fargate Profiles
# ========================================

resource "aws_eks_fargate_profile" "this" {
  for_each = var.fargate_profiles

  cluster_name           = var.cluster_name
  fargate_profile_name   = each.key
  pod_execution_role_arn = module.iam.fargate_role_arns[each.key]
  subnet_ids             = each.value.subnet_ids

  selector {
    namespace = each.key
    labels    = each.value.namespace_labels
  }

  tags = merge(var.tags, each.value.tags, {
    Name = "${var.cluster_name}-${each.key}"
  })
}

# ========================================
# EKS Access Entries
# ========================================

resource "aws_eks_access_entry" "this" {
  for_each = var.access_entries

  cluster_name  = var.cluster_name
  principal_arn = each.key
  type          = "STANDARD"

  user_name = each.value.user_name

  tags = var.tags
}

resource "aws_eks_access_policy_association" "this" {
  for_each = var.access_entries

  cluster_name  = var.cluster_name
  principal_arn = each.key

  dynamic "policy_association" {
    for_each = each.value.policy_arns
    content {
      policy_arn = policy_association.value
    }
  }

  tags = var.tags
}

# ========================================
# Variables
# ========================================

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "cluster_security_group_id" {
  description = "Security group for the EKS cluster"
  type        = string
}

variable "enable_irsa" {
  description = "Enable IRSA"
  type        = bool
  default     = true
}

variable "irsa_oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  type        = string
  default     = ""
}

variable "kube_proxy_version" {
  description = "Version for kube-proxy addon"
  type        = string
  default     = ""
}

variable "vpc_cni_version" {
  description = "Version for VPC CNI addon"
  type        = string
  default     = "latest"
}

variable "coredns_version" {
  description = "Version for CoreDNS addon"
  type        = string
  default     = "latest"
}

variable "eks_managed_node_groups" {
  description = "EKS managed node group configurations"
  type = map(object({
    instance_types  = list(string)
    min_size        = number
    max_size        = number
    desired_size    = number
    capacity_type   = optional(string, "ON_DEMAND")
    disk_size       = optional(number, 100)
    ami_type        = optional(string, "AL2_x86_64")
    ami_release_version = optional(string, null)
    subnets         = optional(list(string), null)
    taints          = optional(map(list(string)), {})
    labels          = optional(map(string), {})
    tags            = optional(map(string), {})
  }))
  default = {}
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

variable "access_entries" {
  description = "EKS access entries"
  type = map(object({
    user_name     = optional(string, null)
    kubernetes_groups = optional(list(string), [])
    policy_arns   = optional(list(string), [])
  }))
  default = {}
}

variable "cluster_encryption_config" {
  description = "EBS encryption configuration"
  type = list(object({
    provider_key_arn = string
  }))
  default = []
}

variable "log_types" {
  description = "Log types to enable on the cluster"
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
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
