variable "cluster_name" {
  type = string
}

variable "chart_version" {
  type    = string
  default = "7.0.0"
}

resource "helm_release" "grafana" {
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  namespace        = "monitoring"
  create_namespace = true
  version          = var.chart_version

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }
  set {
    name  = "adminPassword"
    value = "admin"
  }
}
