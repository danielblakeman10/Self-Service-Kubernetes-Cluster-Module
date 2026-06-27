# Self-Service Kubernetes Cluster Module

<p align="center">
  <img src="https://img.shields.io/badge/Status-Production%20Ready-brightgreen" alt="Status">
  <img src="https://img.shields.io/badge/Infrastructure-Terraform%20EKS-blue" alt="Terraform EKS">
  <img src="https://img.shields.io/badge/Cloud-AWS-orange" alt="AWS">
  <img src="https://img.shields.io/badge/Kubernetes-1.28%2B-yellow" alt="Kubernetes">
  <img src="https://img.shields.io/badge/License-MIT-lightgrey" alt="License">
</p>

## 📦 Terraform EKS Module

A production-ready, self-service Terraform module for provisioning secure, scalable Kubernetes clusters on AWS EKS with managed node groups, IRSA, cluster autoscaler, and GitOps-ready networking.

## 🚀 Features

| Feature | Description |
|---------|-------------|
| **Managed EKS Cluster** | AWS-managed control plane with auto-updates |
| **Managed Node Groups** | Fargate + EC2 mixed node groups with auto-scaling |
| **IRSA Support** | IAM Roles for Service Accounts — pod-level permissions |
| **VPC CNI Addon** | Native pod networking with IP-per-pod |
| **Cluster Autoscaler** | Automatic node scaling based on resource requests |
| **Multi-AZ Design** | 3-AZ subnet deployment for high availability |
| **Encryption at Rest** | EBS volumes and EFS encrypted with KMS |
| **Remote State** | S3 backend + DynamoDB state locking |

## 🏗 Architecture

```
                           ┌─────────────────────────────┐
                           │      VPC (10.0.0.0/16)      │
                           │                             │
    ┌──────────┐  ┌────────┴────────┐  ┌──────────┐     │
    │  Public  │  │   Private       │  │  Private │     │
    │ Subnets  │  │  Subnets (3AZ)  │  │  Subnets │     │
    │ (3AZ)    │  │  (3AZ)          │  │  (3AZ)   │     │
    └────┬─────┘  └────────┬────────┘  └────┬─────┘     │
         │                 │                │           │
    ┌────┴─────┐    ┌──────┴───────┐  ┌─────┴─────┐    │
    │ NAT GW   │    │  EKS Control │  │  Pod CIDR │    │
    │ (outbound)│   │  Plane (AWS) │  │  10.1.0.0 │    │
    └──────────┘    └──────────────┘  └───────────┘    │
                           │                             │
                    ┌──────┴───────┐                    │
                    │  Node Groups  │                    │
                    │  • Worker x3  │                    │
                    │  • Fargate    │                    │
                    └──────────────┘                    │
                           └─────────────────────────────┘
```

## 📁 Project Structure

```
├── main.tf                    # Core EKS cluster, node groups, addons
├── variables.tf               # Input variables with validation
├── outputs.tf                 # Cluster endpoint, ARN, security group IDs
├── vpc.tf                     # VPC, subnets, IGW, NAT GW, route tables
├── iam.tf                     # IRSA roles, EKS service roles
├── addons.tf                  # VPC CNI, CoreDNS, kube-proxy, autoscaler
├── autoscaler.tf              # Cluster autoscaler deployment + IAM
├── examples/
│   ├── complete/
│   │   ├── main.tf            # Full working example
│   │   └── variables.tf       # Example variable values
│   └── minimal/
│       └── main.tf            # Minimal cluster only
├── environments/
│   ├── dev/
│   │   ├── main.tf            # Dev environment override
│   │   └── variables.tf
│   ├── staging/
│   │   └── ...
│   └── prod/
│       └── ...
├── .github/
│   └── workflows/
│       ├── terraform.yml      # Plan/apply CI
│       └── validate.yml       # tflint + checkov
├── .gitignore
├── README.md
└── LICENSE
```

## 🛠 Tech Stack

| Technology | Purpose |
|-----------|---------|
| **Terraform** | Infrastructure provisioning |
| **AWS EKS** | Managed Kubernetes service |
| **VPC** | Network isolation with public/private subnets |
| **IAM** | IRSA for pod-level permissions |
| **Amazon EBS** | Block storage with KMS encryption |
| **Amazon EFS** | Shared filesystem for stateful workloads |
| **Kubernetes** | Container orchestration |
| **Helm** | Application deployment on the cluster |

## 🚦 Quick Start

### 1. Clone & Initialize

```bash
git clone https://github.com/danielblakeman10/Self-Service-Kubernetes-Cluster-Module.git
cd Self-Service-Kubernetes-Cluster-Module

terraform init
```

### 2. Review Plan

```bash
terraform plan \
  -var='cluster_name=my-cluster' \
  -var='environment=production' \
  -var='desired_capacity=3' \
  -var='max_size=10'
```

### 3. Deploy

```bash
terraform apply \
  -var='cluster_name=my-cluster' \
  -var='environment=production'
```

### 4. Configure kubectl

```bash
aws eks update-kubeconfig \
  --name my-cluster \
  --region us-east-2

kubectl get nodes
```

## 📋 Variable Reference

| Variable | Type | Default | Description |
|---------|------|---------|-------------|
| `cluster_name` | `string` | `"eks-cluster"` | Name of the EKS cluster |
| `environment` | `string` | `"dev"` | Environment name (dev/staging/prod) |
| `vpc_cidr` | `string` | `"10.0.0.0/16"` | VPC CIDR block |
| `cluster_version` | `string` | `"1.28"` | Kubernetes version |
| `node_groups` | `map` | — | Map of node group configs |
| `enable_autoscaler` | `bool` | `true` | Enable cluster autoscaler |
| `enable_fargate` | `bool` | `true` | Enable Fargate profile |

## 🔐 Security

- **Private control plane** — EKS API endpoint not internet-exposed
- **IRSA** — Pods get scoped IAM permissions, no node-level secrets
- **Encryption at rest** — EBS, EFS, and secrets encrypted with KMS
- **Security groups** — EKS cluster SG allows only VPC CIDR on 443
- **Network policies** — Pod-to-pod traffic controlled via Calico/Cilium
- **Node isolation** — No public IP on worker nodes

## 📊 Cost Estimate

| Resource | Dev (1 node) | Staging (3 nodes) | Prod (5 nodes) |
|---------|-------------|-------------------|----------------|
| EKS Control Plane | $73/mo | $73/mo | $73/mo |
| Worker Nodes | $73/mo | $219/mo | $365/mo |
| NAT Gateway | $32/mo | $32/mo | $32/mo |
| **Total** | **~$178/mo** | **~$324/mo** | **~$470/mo** |

*Prices based on us-east-2 t3.medium instances*

## 📦 Environments

### Dev
- 1 t3.small worker node
- Fargate for burst workloads
- Limited autoscaling (1-2 nodes)

### Staging
- 3 t3.medium worker nodes
- Fargate for additional capacity
- Autoscaling (2-6 nodes)
- Same configs as prod, less scale

### Production
- 5+ t3.large worker nodes
- Multi-AZ deployment
- Autoscaling (3-15 nodes)
- Reserved instances for cost savings
- Backup and disaster recovery

## 📄 License

MIT License — see `LICENSE` for details.
