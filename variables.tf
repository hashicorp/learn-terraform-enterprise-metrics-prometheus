# Declare variables.
variable "aws_region" {
  description = "Region in which AWS resources to be created"
  type        = string
}

variable "tfe_tag_name" {
  description = "Tag name for TFE instance"
  type        = string
}

variable "subnet_id" {
description = "Subnet of existing TFE instance"
type        = string
}
