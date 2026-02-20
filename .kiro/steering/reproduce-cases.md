---
inclusion: manual
---

# EKS Reproduction Cases

When the user asks to reproduce an issue or set up a test environment, follow these steps:

## Available Cases

Check `reproduce/cases/` directory for existing reproduction cases:
- CASE-001-istio-memory.yaml - Istio 1.19 sidecar memory leak
- CASE-002-karpenter-spot.yaml - Karpenter spot interruption handling
- CASE-003-alb-waf.yaml - ALB Controller WAF association failure

## How to Use

1. **Find matching case**: Search cases by component name or issue description
2. **Read case file**: Parse the YAML to understand setup requirements
3. **Execute steps**: Run setup, test, verify in order

## Case File Structure

```yaml
name: "Issue title"
ticket: "CASE-XXXXX"
description: "Detailed description"

components:
  <addon>: "<version>"

setup:
  - action: terraform|kubectl
    addons: {}        # for terraform
    files: []         # for kubectl
    manifest: |       # inline yaml

test:
  - name: "Step name"
    command: "shell command"

verify:
  - name: "Verification name"
    command: "shell command"

cleanup:
  - action: terraform|kubectl
    command: "cleanup command"
```

## Commands

```bash
# Setup environment
./reproduce/scripts/reproduce.sh setup CASE-001-istio-memory.yaml

# Run tests
./reproduce/scripts/reproduce.sh test CASE-001-istio-memory.yaml

# Verify
./reproduce/scripts/reproduce.sh verify CASE-001-istio-memory.yaml

# Full cycle
./reproduce/scripts/reproduce.sh full CASE-001-istio-memory.yaml

# Cleanup
./reproduce/scripts/reproduce.sh cleanup CASE-001-istio-memory.yaml
```

## Creating New Cases

When user describes a new issue to reproduce:
1. Create new case file in `reproduce/cases/`
2. Define components with specific versions
3. Add setup steps (terraform addons + kubectl manifests)
4. Add test and verify commands
5. Add cleanup steps
