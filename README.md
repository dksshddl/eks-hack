# EKS Third-Party Addons Terraform

Deploy third-party addons to existing EKS clusters via Helm using Terraform.

## Quick Start

```bash
cd terraform && terraform init
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

## VPC Endpoints (Private Cluster)

For private EKS clusters, enable VPC endpoints:

```hcl
create_vpc_endpoints           = true
vpc_endpoint_subnet_ids        = ["subnet-xxx", "subnet-yyy"]
vpc_endpoint_security_group_id = "sg-xxx"
```

Creates the following endpoints required for Karpenter and EKS:
- `ec2`, `ecr.api`, `ecr.dkr` (Interface)
- `sts`, `ssm`, `sqs`, `eks` (Interface)
- `s3` (Gateway)

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

## Reproduction Cases (AI-Assisted)

For support engineers to reproduce customer issues:

```bash
# List available cases
ls reproduce/cases/

# Run full reproduction cycle
./reproduce/scripts/reproduce.sh full CASE-001-istio-memory.yaml

# Or step by step
./reproduce/scripts/reproduce.sh setup CASE-001-istio-memory.yaml
./reproduce/scripts/reproduce.sh test CASE-001-istio-memory.yaml
./reproduce/scripts/reproduce.sh verify CASE-001-istio-memory.yaml
./reproduce/scripts/reproduce.sh cleanup CASE-001-istio-memory.yaml
```

With Kiro AI, just describe the issue:
```
"Istio 1.19.3 버전으로 메모리 누수 재현 환경 만들어줘"
"Karpenter 0.32에서 Spot 인터럽션 테스트해줘"
```

Case files are in `reproduce/cases/` - AI reads these and executes automatically.

## MCP Servers

Pre-configured MCP servers in `.kiro/settings/mcp.json`:

| Server | Description |
|--------|-------------|
| `aws-docs` | AWS documentation search |
| `aws-core` | AWS core services (EC2, IAM, CloudWatch) |
| `aws-eks` | EKS-specific operations |
| `kubernetes` | kubectl commands, pod logs, metrics |

Example AI queries with MCP:
```
"eks-133 클러스터 노드 상태 확인해줘"
"karpenter pod 로그에서 에러 찾아줘"
"istio-proxy 메모리 사용량 봐줘"
"SQS 큐에 인터럽션 메시지 있는지 확인해줘"
```
