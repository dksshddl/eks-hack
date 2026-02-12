#!/bin/bash
set -e

# 기본값
SUBNET_TYPE="${SUBNET_TYPE:-private}"
AMI_ALIAS="${AMI_ALIAS:-al2023@latest}"
OUTPUT_DIR="yaml/karpenter/generated"

usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -s, --subnet-type    Subnet type: private, public, private-custom (default: private)"
  echo "  -a, --ami-alias      AMI alias (default: al2023@latest)"
  echo "  -d, --dry-run        Generate files only, don't apply"
  echo "  -h, --help           Show this help"
  echo ""
  echo "Examples:"
  echo "  $0                                    # private subnet, al2023"
  echo "  $0 -s public                          # public subnet"
  echo "  $0 -s private -a al2@latest           # private subnet, AL2"
  echo "  $0 -d                                 # dry-run (generate only)"
  exit 0
}

DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -s|--subnet-type) SUBNET_TYPE="$2"; shift 2 ;;
    -a|--ami-alias) AMI_ALIAS="$2"; shift 2 ;;
    -d|--dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

# Terraform output에서 값 추출
CLUSTER_NAME=$(terraform -chdir=terraform output -raw cluster_name)
CLUSTER_SG=$(terraform -chdir=terraform output -raw eks_cluster_security_group_id)

echo "=== Configuration ==="
echo "Cluster: $CLUSTER_NAME"
echo "Security Group: $CLUSTER_SG"
echo "Subnet Type: $SUBNET_TYPE"
echo "AMI Alias: $AMI_ALIAS"
echo ""

# 출력 디렉토리 생성
mkdir -p "$OUTPUT_DIR"

# EC2NodeClass 생성
export CLUSTER_NAME CLUSTER_SG SUBNET_TYPE AMI_ALIAS
envsubst < yaml/karpenter/ec2nodeclass.yaml > "$OUTPUT_DIR/ec2nodeclass.yaml"
envsubst < yaml/karpenter/nodepool.yaml > "$OUTPUT_DIR/nodepool.yaml"

echo "Generated files:"
echo "  - $OUTPUT_DIR/ec2nodeclass.yaml"
echo "  - $OUTPUT_DIR/nodepool.yaml"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "Dry-run mode. Files generated but not applied."
  exit 0
fi

# kubectl apply
echo "Applying to cluster..."
kubectl apply -f "$OUTPUT_DIR/ec2nodeclass.yaml"
kubectl apply -f "$OUTPUT_DIR/nodepool.yaml"

echo ""
echo "Done!"
