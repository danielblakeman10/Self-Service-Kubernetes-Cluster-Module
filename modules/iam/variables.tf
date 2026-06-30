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
