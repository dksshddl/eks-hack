#!/bin/bash
set -e

CASES_DIR="reproduce/cases"
TERRAFORM_DIR="terraform"

usage() {
  echo "Usage: $0 <action> <case-file> [options]"
  echo ""
  echo "Actions:"
  echo "  setup     - Set up reproduction environment"
  echo "  test      - Run test steps"
  echo "  verify    - Run verification steps"
  echo "  cleanup   - Clean up resources"
  echo "  full      - Run setup -> test -> verify"
  echo ""
  echo "Options:"
  echo "  --cluster <name>   Cluster name (default: from case file)"
  echo "  --dry-run          Print commands without executing"
  echo ""
  echo "Examples:"
  echo "  $0 setup reproduce/cases/CASE-001-istio-memory.yaml"
  echo "  $0 full CASE-001-istio-memory.yaml --cluster eks-test"
  exit 1
}

[ $# -lt 2 ] && usage

ACTION=$1
CASE_FILE=$2
shift 2

CLUSTER_NAME=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --cluster) CLUSTER_NAME="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

# Resolve case file path
if [[ ! -f "$CASE_FILE" ]]; then
  CASE_FILE="$CASES_DIR/$CASE_FILE"
fi
if [[ ! -f "$CASE_FILE" ]]; then
  CASE_FILE="$CASES_DIR/${CASE_FILE}.yaml"
fi
if [[ ! -f "$CASE_FILE" ]]; then
  echo "Case file not found: $CASE_FILE"
  exit 1
fi

echo "=== Case: $(yq '.name' $CASE_FILE) ==="
echo "Ticket: $(yq '.ticket' $CASE_FILE)"
echo "Description: $(yq '.description' $CASE_FILE)"
echo ""

run_cmd() {
  if [ "$DRY_RUN" = true ]; then
    echo "[DRY-RUN] $1"
  else
    echo "[RUN] $1"
    eval "$1"
  fi
}

case $ACTION in
  setup)
    echo "=== Setting up environment ==="
    ADDONS=$(yq -o=json '.setup[] | select(.action == "terraform") | .addons' $CASE_FILE 2>/dev/null | head -1)
    if [ -n "$ADDONS" ] && [ "$ADDONS" != "null" ]; then
      echo "Applying Terraform addons..."
      ADDON_ARGS=$(echo $ADDONS | jq -r 'to_entries | map("\(.key)=\"\(.value)\"") | join(",")')
      run_cmd "cd $TERRAFORM_DIR && terraform apply -var='addons={$ADDON_ARGS}' -auto-approve"
    fi
    
    # Apply kubectl files
    yq -o=json '.setup[] | select(.action == "kubectl") | .files[]?' $CASE_FILE 2>/dev/null | while read -r file; do
      file=$(echo $file | tr -d '"')
      [ -n "$file" ] && run_cmd "kubectl apply -f $file"
    done
    
    # Apply inline manifests
    yq '.setup[] | select(.action == "kubectl") | .manifest' $CASE_FILE 2>/dev/null | while read -r manifest; do
      [ -n "$manifest" ] && [ "$manifest" != "null" ] && echo "$manifest" | run_cmd "kubectl apply -f -"
    done
    ;;
    
  test)
    echo "=== Running tests ==="
    yq -o=json '.test[]' $CASE_FILE 2>/dev/null | while read -r step; do
      name=$(echo $step | jq -r '.name')
      cmd=$(echo $step | jq -r '.command')
      echo "--- $name ---"
      run_cmd "$cmd"
    done
    ;;
    
  verify)
    echo "=== Running verification ==="
    yq -o=json '.verify[]' $CASE_FILE 2>/dev/null | while read -r step; do
      name=$(echo $step | jq -r '.name')
      cmd=$(echo $step | jq -r '.command')
      echo "--- $name ---"
      run_cmd "$cmd"
    done
    ;;
    
  cleanup)
    echo "=== Cleaning up ==="
    yq -o=json '.cleanup[]' $CASE_FILE 2>/dev/null | while read -r step; do
      action=$(echo $step | jq -r '.action')
      if [ "$action" = "kubectl" ]; then
        cmd=$(echo $step | jq -r '.command')
        run_cmd "$cmd"
      elif [ "$action" = "terraform" ]; then
        run_cmd "cd $TERRAFORM_DIR && terraform apply -var='addons={}' -auto-approve"
      fi
    done
    ;;
    
  full)
    $0 setup $CASE_FILE ${CLUSTER_NAME:+--cluster $CLUSTER_NAME} ${DRY_RUN:+--dry-run}
    $0 test $CASE_FILE ${DRY_RUN:+--dry-run}
    $0 verify $CASE_FILE ${DRY_RUN:+--dry-run}
    ;;
    
  *)
    usage
    ;;
esac

echo ""
echo "=== Done ==="
