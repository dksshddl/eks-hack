variable "cluster_name" {
  type = string
}

variable "chart_version" {
  type    = string
  default = "5.51.0"
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = var.chart_version

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }
}
