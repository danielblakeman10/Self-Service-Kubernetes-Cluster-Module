# Autoscaler module variables

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "enable_autoscaler" {
  description = "Deploy cluster autoscaler"
  type        = bool
  default     = true
}

variable "oidc_provider_url" {
  description = "OIDC provider URL (used for IRSA role ARN construction)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
