### shared 

variable "project" {
  description = "associated project or app"
  type        = string
}

variable "environment" {
  description = "associated environment"
  type        = string
}

variable "region" {
  description = "associated region"
  type        = string
}

variable "vpc_id" {
  description = "ID of existing VPC"
  type        = string
}

variable "vpc_subnet_ids" {
  description = "subnet IDs of VPC"
  type        = list(string)
}

### ecs
variable "container_image" {
  description = "container image name with tag"
  type        = string
}
variable "container_comm01" {
  description = "first container command"
  type        = string
}
variable "container_comm02" {
  description = "second container command"
  type        = string
}
variable "container_mem" {
  description = "container memory"
  type        = number
}
variable "container_cpu" {
  description = "container cpu"
  type        = number
}
### s3
variable "s3_bucket" {
  description = "s3 bucket for pgdump via ecs"
  type        = string
}
variable "s3_days_until_glacier" {
  description = "days until moving to glacier tier"
  type        = number
}
variable "s3_days_until_expiry" {
  description = "days until deletion"
  type        = number
}

###  security group
variable "sgr_ingress_cidr_blocks" {
  description = "Source networks for incoming traffic"
  type        = list(string)
}
variable "sgr_cidr_blocks" {
  description = "Source networks for incoming traffic"
  type        = string
}

### eventbridge
variable "tag_backup" {
  description = "tag key for backup"
  type        = string
}
variable "event_cron" {
  description = "event cron schedule for backup"
  type        = string
}