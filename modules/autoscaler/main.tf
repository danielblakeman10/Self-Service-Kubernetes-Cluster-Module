# Cluster Autoscaler Module - Kubernetes Cluster Autoscaler deployment with IRSA

resource "kubernetes_namespace" "autoscaler" {
  count = var.enable_autoscaler ? 1 : 0

  metadata {
    name = "kube-system"

    labels = {
      "app.kubernetes.io/name"       = "cluster-autoscaler"
      "app.kubernetes.io/component"  = "autoscaler"
    }
  }
}

resource "helm_release" "autoscaler" {
  count = var.enable_autoscaler ? 1 : 0

  name       = "cluster-autoscaler"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.37.0"

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.region
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.oidc_provider_url != "" ? "arn:aws:iam::${var.cluster_name}-autoscaler-role" : ""
  }

  set {
    name  = "extraArgs.balance-similar-node-groups"
    value = "true"
  }

  set {
    name  = "extraArgs.skip-nodes-with-local-storage"
    value = "false"
  }

  set {
    name  = "extraArgs.scale-down-utilization-threshold"
    value = "0.5"
  }

  set {
    name  = "extraArgs.scale-down-delay-after-add"
    value = "10m"
  }

  set {
    name  = "extraArgs.scale-down-delay-after-delete"
    value = "30s"
  }

  set {
    name  = "extraArgs.scale-down-unneeded-time"
    value = "10m"
  }

  set {
    name  = "extraArgs.skip-nodes-with-system-pods"
    value = "true"
  }

  values = [<<EOF
image:
  repository: registry.k8s.io/autoscaling/cluster-autoscaler
  tag: v1.29.0
  pullPolicy: IfNotPresent

resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi

podAnnotations:
  cluster-autoscaler.kubernetes.io/scale-down-disabled: "false"
  cluster-autoscaler.kubernetes.io/scale-down-utilization-threshold: "0.5"

persistence:
  enabled: false

EOF
  ]

  depends_on = [kubernetes_namespace.autoscaler]
}

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

output "release_name" {
  description = "Helm release name"
  value       = var.enable_autoscaler ? helm_release.autoscaler[0].name : ""
}

output "release_namespace" {
  description = "Helm release namespace"
  value       = var.enable_autoscaler ? helm_release.autoscaler[0].namespace : ""
}
