# Helm Application Example - EKS with Helm chart deployment

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0"
    }
    aws-native = {
      source  = "hashicorp/aws-native"
      version = ">= 0.5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", "my-helm-cluster"]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", "my-helm-cluster"]
    }
  }
}

module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr           = "10.2.0.0/16"
  cluster_name       = "my-helm-cluster"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  tags = {
    Environment = "staging"
    Example     = "helm-app"
  }
}

module "eks" {
  source = "../../"

  cluster_name    = "my-helm-cluster"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa      = true
  enable_autoscaler = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 5
      desired_size   = 2
    }
  }

  tags = {
    Environment = "staging"
    Example     = "helm-app"
  }
}

# Deploy sample application via Helm
resource "helm_release" "my_app" {
  name       = "my-app"
  namespace  = "default"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx"
  version    = "15.5.0"

  values = [
    <<EOF
replicaCount: 2

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi
EOF
    ]

  depends_on = [module.eks]
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --name my-helm-cluster --region us-east-1"
}
