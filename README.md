# EKS Third-Party Addons Terraform

Deploy third-party addons to existing EKS clusters via Helm using Terraform.

## Quick Start

```bash
terraform init
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars (cluster_name, vpc_id, addons)
terraform apply
```

## Multi-Cluster Management (Workspaces)

Use Terraform Workspaces to manage separate tfstate per cluster:

```bash
# Create workspaces
terraform workspace new cluster1
terraform workspace new cluster2

# List workspaces
terraform workspace list

# Switch workspace
terraform workspace select cluster1

# Apply to current workspace
terraform apply -var="cluster_name=cluster1" -var="vpc_id=vpc-xxx" -var='addons=["karpenter","argo"]'

# Switch and apply to another cluster
terraform workspace select cluster2
terraform apply -var="cluster_name=cluster2" -var="vpc_id=vpc-yyy" -var='addons=["istio","prometheus"]'
```

S3 Backend configuration (`backend.tf`):

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "eks-addons/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
```

State file paths:
- cluster1 → `env:/cluster1/eks-addons/terraform.tfstate`
- cluster2 → `env:/cluster2/eks-addons/terraform.tfstate`

## Supported Addons

| Addon | Description |
|-------|-------------|
| `istio` | Service mesh |
| `karpenter` | Node autoprovisioning |
| `keda` | Event-driven autoscaling |
| `argo` | ArgoCD GitOps |
| `prometheus` | Metrics collection |
| `grafana` | Visualization dashboard |
| `cluster-autoscaler` | Node autoscaling |
| `aws-load-balancer-controller` | ALB/NLB controller |

## Outputs

| Output | Description |
|--------|-------------|
| `eks_cluster_security_group_id` | EKS cluster security group |
| `karpenter_discovery_subnets` | Subnets tagged with `karpenter.sh/discovery` |

## Adding New Addons

1. Create `modules/<addon-name>/main.tf`
2. Add module block to `addons.tf`:

```hcl
module "new_addon" {
  source       = "./modules/new-addon"
  count        = contains(var.addons, "new-addon") ? 1 : 0
  cluster_name = var.cluster_name
}
```

## YAML Examples

Example manifests for testing each addon are in the `yaml/` directory:

```
yaml/
├── karpenter/
│   ├── ec2nodeclass.yaml      # Template
│   ├── nodepool.yaml          # Template
│   └── generated/             # Generated files (gitignored)
├── aws-lb-controller/
│   ├── ingress.yaml           # ALB Ingress
│   ├── service-nlb.yaml       # NLB Service
│   ├── gateway.yaml           # Gateway API
│   └── test-app.yaml          # Test deployment
├── istio/
│   ├── gateway.yaml           # Ingress gateway
│   ├── virtualservice.yaml    # Traffic routing
│   ├── destinationrule.yaml   # Traffic policy
│   ├── peerauthentication.yaml # mTLS settings
│   └── telemetry.yaml         # Observability config
├── prometheus/
│   ├── servicemonitor.yaml    # Service metrics
│   └── podmonitor.yaml        # Pod metrics
├── grafana/
│   └── dashboard-configmap.yaml
├── keda/
│   ├── scaledobject.yaml      # CPU-based scaling
│   └── scaledobject-sqs.yaml  # SQS-based scaling
├── cluster-autoscaler/
│   ├── test-deployment.yaml   # Scale-out test
│   └── priority-expander.yaml # Node group priority
└── opentelemetry/
    ├── collector.yaml         # OTel Collector
    └── instrumentation.yaml   # Auto-instrumentation
```

## Scripts

### Karpenter Deployment

Generate and apply Karpenter manifests from templates:

```bash
# Default (private subnet, al2023)
./scripts/apply-karpenter.sh

# Custom subnet type
./scripts/apply-karpenter.sh -s public

# Custom AMI
./scripts/apply-karpenter.sh -a al2@latest

# Dry-run (generate only)
./scripts/apply-karpenter.sh -d
```

Options:
- `-s, --subnet-type`: private, public, private-custom (default: private)
- `-a, --ami-alias`: AMI alias (default: al2023@latest)
- `-d, --dry-run`: Generate files without applying
