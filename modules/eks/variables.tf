# EKS Module variables

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
    instance_types    = list(string)
    min_size          = number
    max_size          = number
    desired_size      = number
    capacity_type     = optional(string, "ON_DEMAND")
    disk_size         = optional(number, 100)
    ami_type          = optional(string, "AL2_x86_64")
    ami_release_version = optional(string, null)
    subnets           = optional(list(string), null)
    taints            = optional(map(list(string)), {})
    labels            = optional(map(string), {})
    tags              = optional(map(string), {})
  }))
  default = {}
}

variable "fargate_profiles" {
  description = "Fargate profile configurations"
  type = map(object({
    name             = string
    subnet_ids       = list(string)
    namespace_labels = optional(map(string), {})
    tags             = optional(map(string), {})
  }))
  default = {}
}

variable "access_entries" {
  description = "EKS access entries"
  type = map(object({
    user_name         = optional(string, null)
    kubernetes_groups = optional(list(string), [])
    policy_arns       = optional(list(string), [])
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
