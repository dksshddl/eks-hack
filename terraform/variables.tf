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
}

variable "create_vpc_endpoints" {
  description = "Create VPC endpoints for private EKS cluster"
  type        = bool
  default     = false
}

variable "vpc_endpoint_subnet_ids" {
  description = "Subnet IDs for VPC endpoints"
  type        = list(string)
  default     = []
}

variable "vpc_endpoint_security_group_id" {
  description = "Security group ID for VPC endpoints"
  type        = string
  default     = ""
}
