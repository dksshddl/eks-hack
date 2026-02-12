variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "endpoints" {
  description = "List of VPC endpoints to create"
  type        = set(string)
  default = [
    "ec2",
    "ecr.api",
    "ecr.dkr",
    "s3",
    "sts",
    "ssm",
    "sqs",
    "eks"
  ]
}

locals {
  interface_endpoints = toset([for e in var.endpoints : e if e != "s3"])
  gateway_endpoints   = toset([for e in var.endpoints : e if e == "s3"])
}

# Interface Endpoints
resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [var.security_group_id]
  private_dns_enabled = true

  tags = {
    Name = "vpce-${each.value}"
  }
}

# Gateway Endpoint (S3)
data "aws_route_tables" "private" {
  vpc_id = var.vpc_id

  filter {
    name   = "association.main"
    values = ["false"]
  }
}

resource "aws_vpc_endpoint" "gateway" {
  for_each = local.gateway_endpoints

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = data.aws_route_tables.private.ids

  tags = {
    Name = "vpce-${each.value}"
  }
}

output "endpoint_ids" {
  value = merge(
    { for k, v in aws_vpc_endpoint.interface : k => v.id },
    { for k, v in aws_vpc_endpoint.gateway : k => v.id }
  )
}
