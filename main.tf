# ========================================
# EKS Module Root - Main Configuration
# ========================================

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

# ========================================
# VPC Module
# ========================================

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr           = var.vpc_cidr
  cluster_name       = var.cluster_name
  availability_zones = var.availability_zones

  tags = var.tags
}

# ========================================
# IAM Module
# ========================================

module "iam" {
  source = "./modules/iam"

  cluster_name           = var.cluster_name
  enable_irsa            = var.enable_irsa
  enable_autoscaler      = var.enable_autoscaler
  enable_fargate         = var.enable_fargate
  oidc_provider_url      = module.eks.oidc_provider_url
  region                 = var.region

  tags = var.tags
}

# ========================================
# EKS Cluster Module
# ========================================

module "eks" {
  source = "./modules/eks"

  cluster_name           = var.cluster_name
  cluster_version        = var.cluster_version
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnets
  cluster_security_group_id = module.vpc.cluster_security_group_id

  enable_irsa            = var.enable_irsa
  irsa_oidc_provider_arn = module.iam.oidc_provider_arn

  kube_proxy_version     = var.kube_proxy_version
  vpc_cni_version        = var.vpc_cni_version
  coredns_version        = var.coredns_version

  eks_managed_node_groups = var.eks_managed_node_groups
  fargate_profiles        = var.fargate_profiles
  access_entries          = var.access_entries
  cluster_encryption_config = var.cluster_encryption_config
  log_types               = var.log_types

  oidc_provider_tags = var.oidc_provider_tags

  tags = var.tags
}

# ========================================
# Cluster Autoscaler Module
# ========================================

module "autoscaler" {
  source = "./modules/autoscaler"

  cluster_name = var.cluster_name
  region       = var.region
  oidc_provider_url = module.eks.oidc_provider_url

  enable_irsa       = var.enable_irsa
  enable_autoscaler = var.enable_autoscaler

  tags = var.tags
}

# ========================================
# Variables
# ========================================

variable "region" {
  description = "AWS region for the EKS cluster"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for the EKS cluster"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts"
  type        = bool
  default     = true
}

variable "enable_autoscaler" {
  description = "Deploy the Kubernetes cluster autoscaler"
  type        = bool
  default     = true
}

variable "enable_fargate" {
  description = "Enable Fargate profiles for the EKS cluster"
  type        = bool
  default     = false
}

variable "kube_proxy_version" {
  description = "Version of the kube-proxy addon"
  type        = string
  default     = ""
}

variable "vpc_cni_version" {
  description = "Version of the VPC CNI addon"
  type        = string
  default     = "latest"
}

variable "coredns_version" {
  description = "Version of the CoreDNS addon"
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
    name              = string
    subnet_ids        = list(string)
    namespace_labels  = optional(map(string), {})
    tags              = optional(map(string), {})
  }))
  default = {}
}

variable "access_entries" {
  description = "EKS access entries for IAM users/roles"
  type = map(object({
    user_name    = optional(string, null)
    kubernetes_groups = optional(list(string), [])
    policy_arns  = optional(list(string), [
      "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy",
      "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy",
      "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
    ])
  }))
  default = {}
}

variable "cluster_encryption_config" {
  description = "EBS encryption configuration for the cluster"
  type = list(object({
    provider_key_arn = string
  }))
  default = []
}

variable "log_types" {
  description = "EKS cluster log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
}

variable "oidc_provider_tags" {
  description = "Tags for the OIDC provider"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

# ========================================
# Outputs
# ========================================

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded CA certificate"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_security_group_id" {
  description = "Security group attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group for the worker nodes"
  value       = module.eks.node_security_group_id
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = module.iam.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider"
  value       = module.iam.oidc_provider_url
}

output "fargate_profile_iam_role_arns" {
  description = "ARNs of the Fargate profile IAM roles"
  value       = module.iam.fargate_profile_arns
}

output "autoscaler_iam_role_arn" {
  description = "ARN of the cluster autoscaler IAM role"
  value       = module.iam.autoscaler_role_arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "helm_values" {
  description = "Helm values for kubeconfig authentication"
  value       = module.eks.helm_values
  sensitive   = true
}
