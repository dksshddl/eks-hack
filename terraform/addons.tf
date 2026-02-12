# Third-party addon modules
# Each addon is conditionally deployed based on var.addons

locals {
  # Default versions (used when "latest" or empty)
  default_versions = {
    istio                        = "1.20.0"
    karpenter                    = "1.9.0"
    keda                         = "2.12.0"
    argo                         = "5.51.0"
    prometheus                   = "25.8.0"
    grafana                      = "7.0.0"
    cluster-autoscaler           = "9.37.0"
    aws-load-balancer-controller = "1.7.1"
  }

  # Resolve versions: use specified version or fall back to default
  addon_versions = {
    for name, ver in var.addons :
    name => (ver == "" || ver == "latest") ? local.default_versions[name] : ver
  }
}

module "istio" {
  source        = "./modules/istio"
  count         = contains(keys(var.addons), "istio") ? 1 : 0
  cluster_name  = var.cluster_name
  chart_version = local.addon_versions["istio"]
}

module "karpenter" {
  source            = "./modules/karpenter"
  count             = contains(keys(var.addons), "karpenter") ? 1 : 0
  cluster_name      = var.cluster_name
  karpenter_version = local.addon_versions["karpenter"]
}

module "keda" {
  source        = "./modules/keda"
  count         = contains(keys(var.addons), "keda") ? 1 : 0
  cluster_name  = var.cluster_name
  chart_version = local.addon_versions["keda"]
}

module "argo" {
  source        = "./modules/argo"
  count         = contains(keys(var.addons), "argo") ? 1 : 0
  cluster_name  = var.cluster_name
  chart_version = local.addon_versions["argo"]
}

module "prometheus" {
  source        = "./modules/prometheus"
  count         = contains(keys(var.addons), "prometheus") ? 1 : 0
  cluster_name  = var.cluster_name
  chart_version = local.addon_versions["prometheus"]
}

module "grafana" {
  source        = "./modules/grafana"
  count         = contains(keys(var.addons), "grafana") ? 1 : 0
  cluster_name  = var.cluster_name
  chart_version = local.addon_versions["grafana"]
}

module "cluster_autoscaler" {
  source        = "./modules/cluster-autoscaler"
  count         = contains(keys(var.addons), "cluster-autoscaler") ? 1 : 0
  cluster_name  = var.cluster_name
  chart_version = local.addon_versions["cluster-autoscaler"]
}

module "aws_load_balancer_controller" {
  source        = "./modules/aws-load-balancer-controller"
  count         = contains(keys(var.addons), "aws-load-balancer-controller") ? 1 : 0
  cluster_name  = var.cluster_name
  chart_version = local.addon_versions["aws-load-balancer-controller"]
}

# VPC Endpoints for private EKS cluster
module "vpc_endpoints" {
  source            = "./modules/vpc-endpoints"
  count             = var.create_vpc_endpoints ? 1 : 0
  vpc_id            = var.vpc_id
  subnet_ids        = var.vpc_endpoint_subnet_ids
  security_group_id = var.vpc_endpoint_security_group_id
  region            = var.aws_region
}
