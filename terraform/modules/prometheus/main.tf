variable "cluster_name" {
  type = string
}

variable "chart_version" {
  type    = string
  default = "25.8.0"
}

resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  namespace        = "monitoring"
  create_namespace = true
  version          = var.chart_version

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }
}
