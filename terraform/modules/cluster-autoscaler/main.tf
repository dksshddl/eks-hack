variable "cluster_name" {
  type = string
}

variable "chart_version" {
  type    = string
  default = "9.37.0"
}

data "aws_region" "current" {}

# IAM Role for Pod Identity
resource "aws_iam_role" "cluster_autoscaler" {
  name = "${var.cluster_name}-cluster-autoscaler"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

# Pod Identity Association
resource "aws_eks_pod_identity_association" "cluster_autoscaler" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "cluster-autoscaler"
  role_arn        = aws_iam_role.cluster_autoscaler.arn
}

resource "aws_iam_role_policy" "cluster_autoscaler" {
  name = "ClusterAutoscalerPolicy"
  role = aws_iam_role.cluster_autoscaler.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
          }
        }
      }
    ]
  })
}

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = var.chart_version

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }
  set {
    name  = "awsRegion"
    value = data.aws_region.current.name
  }

  depends_on = [aws_eks_pod_identity_association.cluster_autoscaler]
}

output "role_arn" {
  value = aws_iam_role.cluster_autoscaler.arn
}
