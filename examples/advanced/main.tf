# Advanced Example - Multi-type node groups + Fargate + Spot

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

module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr           = "10.1.0.0/16"
  cluster_name       = "my-prod-cluster"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  tags = {
    Environment = "production"
    Example     = "advanced"
  }
}

module "eks" {
  source = "../../"

  cluster_name    = "my-prod-cluster"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa      = true
  enable_autoscaler = true
  enable_fargate    = true

  eks_managed_node_groups = {
    on_demand = {
      instance_types = ["m5.2xlarge"]
      min_size       = 2
      max_size       = 10
      desired_size   = 4
      capacity_type  = "ON_DEMAND"

      tags = {
        Workload = "critical"
      }
    }

    spot = {
      instance_types = ["m5.xlarge", "m6i.xlarge", "c5.xlarge"]
      min_size       = 1
      max_size       = 20
      desired_size   = 5
      capacity_type  = "SPOT"

      tags = {
        Workload = "best-effort"
      }
    }
  }

  fargate_profiles = {
    default = {
      name    = "default"
      subnet_ids = module.vpc.private_subnets

      namespace_labels = {
        "kubernetes.io/os" = "linux"
      }
    }
  }

  tags = {
    Environment = "production"
    Example     = "advanced"
  }
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --name my-prod-cluster --region us-east-1"
}
