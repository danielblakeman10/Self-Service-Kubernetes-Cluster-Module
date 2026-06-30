# EKS Module Root - Main Entry Point
# https://github.com/danielblakeman10/Self-Service-Kubernetes-Cluster-Module

```hcl
module "eks" {
  source = "danielblakeman10/eks/aws"

  cluster_name    = "my-cluster"
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa      = true
  enable_autoscaler = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["m5.xlarge"]
      min_size       = 2
      max_size       = 10
      desired_size   = 3
    }
  }

  tags = {
    Environment = "production"
  }
}
```

## Quickstart

```bash
# Clone the repository
git clone https://github.com/danielblakeman10/Self-Service-Kubernetes-Cluster-Module.git
cd Self-Service-Kubernetes-Cluster-Module

# Initialize Terraform
terraform init

# Review the plan
terraform plan -var-file=examples/basic/terraform.tfvars

# Apply
terraform apply

# Configure kubectl
aws eks update-kubeconfig --name my-cluster --region us-east-1

# Verify
kubectl get nodes
kubectl cluster-info
```

## Folder Structure

```
Self-Service-Kubernetes-Cluster-Module/
├── main.tf                        # EKS module entry point
├── variables.tf                   # Input variables
├── outputs.tf                     # Module outputs
├── versions.tf                    # Provider/TF version constraints
├── modules/
│   ├── vpc/                       # VPC module (subnets, IGW, NAT)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── eks/                       # EKS cluster + node groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── iam/                       # IAM roles + IRSA
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── autoscaler/                # Cluster autoscaler
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── charts/
│   └── app-chart/                 # Helm chart for application deployment
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           └── hpa.yaml
├── examples/
│   ├── basic/                     # Basic 3-node cluster
│   ├── advanced/                  # Multi-type node groups + Fargate
│   └── helm-app/                  # EKS + Helm deployment
└── README.md
```
