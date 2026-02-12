output "cluster_name" {
  value = var.cluster_name
}

output "installed_addons" {
  value = var.addons
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = data.aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "karpenter_discovery_subnets" {
  description = "Subnets with karpenter.sh/discovery tag"
  value = {
    private        = [for s in data.aws_subnets.karpenter_private.ids : s]
    public         = [for s in data.aws_subnets.karpenter_public.ids : s]
    private_custom = [for s in data.aws_subnets.karpenter_private_custom.ids : s]
  }
}
