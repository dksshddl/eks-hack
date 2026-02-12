variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EKS cluster is deployed"
  type        = string
}

variable "addons" {
  description = "Map of addons to install with versions. Use 'latest' or omit version for latest."
  type        = map(string)
  default     = {}
  # Example:
  # addons = {
  #   karpenter                   = "1.9.0"
  #   istio                       = "1.20.0"
  #   argo                        = "latest"
  #   prometheus                  = ""       # empty = latest
  # }
}
