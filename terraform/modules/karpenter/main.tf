variable "cluster_name" {
  type = string
}

variable "karpenter_version" {
  type    = string
  default = "1.9.0"
}

variable "karpenter_namespace" {
  type    = string
  default = "kube-system"
}

variable "create_spot_service_linked_role" {
  description = "Create Spot Service Linked Role. Set to false if already exists in account."
  type        = bool
  default     = false
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.name
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

# 공식 CloudFormation 템플릿으로 IAM 리소스 생성
data "http" "karpenter_cloudformation" {
  url = "https://raw.githubusercontent.com/aws/karpenter-provider-aws/v${var.karpenter_version}/website/content/en/preview/getting-started/getting-started-with-karpenter/cloudformation.yaml"
}

resource "aws_cloudformation_stack" "karpenter" {
  name          = "Karpenter-${var.cluster_name}"
  capabilities  = ["CAPABILITY_NAMED_IAM"]
  template_body = data.http.karpenter_cloudformation.response_body

  parameters = {
    ClusterName = var.cluster_name
  }
}

# Spot Service Linked Role (optional)
resource "aws_iam_service_linked_role" "spot" {
  count            = var.create_spot_service_linked_role ? 1 : 0
  aws_service_name = "spot.amazonaws.com"
  description      = "Service linked role for EC2 Spot"
}

# Karpenter Controller Role for Pod Identity
resource "aws_iam_role" "karpenter_controller" {
  name = "${var.cluster_name}-karpenter"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

# Attach CloudFormation-created policies to the controller role
resource "aws_iam_role_policy_attachment" "karpenter_node_lifecycle" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = "arn:${local.partition}:iam::${local.account_id}:policy/KarpenterControllerNodeLifecyclePolicy-${var.cluster_name}"
  depends_on = [aws_cloudformation_stack.karpenter]
}

resource "aws_iam_role_policy_attachment" "karpenter_iam_integration" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = "arn:${local.partition}:iam::${local.account_id}:policy/KarpenterControllerIAMIntegrationPolicy-${var.cluster_name}"
  depends_on = [aws_cloudformation_stack.karpenter]
}

resource "aws_iam_role_policy_attachment" "karpenter_eks_integration" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = "arn:${local.partition}:iam::${local.account_id}:policy/KarpenterControllerEKSIntegrationPolicy-${var.cluster_name}"
  depends_on = [aws_cloudformation_stack.karpenter]
}

resource "aws_iam_role_policy_attachment" "karpenter_interruption" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = "arn:${local.partition}:iam::${local.account_id}:policy/KarpenterControllerInterruptionPolicy-${var.cluster_name}"
  depends_on = [aws_cloudformation_stack.karpenter]
}

resource "aws_iam_role_policy_attachment" "karpenter_resource_discovery" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = "arn:${local.partition}:iam::${local.account_id}:policy/KarpenterControllerResourceDiscoveryPolicy-${var.cluster_name}"
  depends_on = [aws_cloudformation_stack.karpenter]
}

# Pod Identity Association
resource "aws_eks_pod_identity_association" "karpenter" {
  cluster_name    = var.cluster_name
  namespace       = var.karpenter_namespace
  service_account = "karpenter"
  role_arn        = aws_iam_role.karpenter_controller.arn
}

# EKS Access Entry for Karpenter Node Role
resource "aws_eks_access_entry" "karpenter_node" {
  cluster_name  = var.cluster_name
  principal_arn = "arn:${local.partition}:iam::${local.account_id}:role/KarpenterNodeRole-${var.cluster_name}"
  type          = "EC2_LINUX"

  depends_on = [aws_cloudformation_stack.karpenter]
}

# Helm Release
resource "helm_release" "karpenter" {
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  namespace        = var.karpenter_namespace
  create_namespace = true
  version          = var.karpenter_version

  set {
    name  = "settings.clusterName"
    value = var.cluster_name
  }
  set {
    name  = "settings.interruptionQueue"
    value = var.cluster_name
  }
  set {
    name  = "controller.resources.requests.cpu"
    value = "1"
  }
  set {
    name  = "controller.resources.requests.memory"
    value = "1Gi"
  }
  set {
    name  = "controller.resources.limits.cpu"
    value = "1"
  }
  set {
    name  = "controller.resources.limits.memory"
    value = "1Gi"
  }

  depends_on = [
    aws_cloudformation_stack.karpenter,
    aws_eks_pod_identity_association.karpenter
  ]
}

output "cloudformation_stack_id" {
  value = aws_cloudformation_stack.karpenter.id
}

output "karpenter_node_role_name" {
  value = "KarpenterNodeRole-${var.cluster_name}"
}

output "karpenter_queue_name" {
  value = var.cluster_name
}
