# Autoscaler module outputs

output "release_name" {
  description = "Helm release name"
  value       = var.enable_autoscaler ? helm_release.autoscaler[0].name : ""
}

output "release_namespace" {
  description = "Helm release namespace"
  value       = var.enable_autoscaler ? helm_release.autoscaler[0].namespace : ""
}
