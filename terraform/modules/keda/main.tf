variable "cluster_name" {
  type = string
}

variable "chart_version" {
  type    = string
  default = "2.12.0"
}

resource "helm_release" "keda" {
  name             = "keda"
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  namespace        = "keda"
  create_namespace = true
  version          = var.chart_version
}
