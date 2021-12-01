provider "aws" {
    region = var.region
}

locals {
  name_prefix = "${var.project}_${var.environment}"
}

locals {
  common_tags = {
    terraform           = "true"
    terraform_workspace = terraform.workspace
    project             = var.project
    environment         = var.environment
    auto-delete         = "no"
  }
}

module "sgr_ecs" {
  source = "terraform-aws-modules/security-group/aws"
  version = ">= 4.7.0"

  name                = "${var.project}-ecs"
  description         = "Security group ECS for Aurora Backup"
  vpc_id              = var.vpc_id
  ingress_cidr_blocks = var.sgr_ingress_cidr_blocks

  ingress_with_cidr_blocks = []

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      description = "all ports"
      cidr_blocks = "0.0.0.0/0"
      self        = true
    }
  ]

  tags = local.common_tags
}
