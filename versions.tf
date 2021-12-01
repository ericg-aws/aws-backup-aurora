terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 3.66.0, < 4.0"
    }
    local      = ">= 1.4"
    random     = ">= 2.1"
  }
  required_version = ">= 1.0.11, < 2.0"
}