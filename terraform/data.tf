data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

# Subnets with karpenter.sh/discovery tag
data "aws_subnets" "karpenter_private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  tags = {
    "karpenter.sh/discovery" = "private"
  }
}

data "aws_subnets" "karpenter_public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  tags = {
    "karpenter.sh/discovery" = "public"
  }
}

data "aws_subnets" "karpenter_private_custom" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  tags = {
    "karpenter.sh/discovery" = "private-custom"
  }
}
