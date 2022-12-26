# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Declare variables.
variable "aws_region" {
  description = "Region in which AWS resources to be created"
  type        = string
}

variable "tfe_tag_name" {
  description = "Tag name for TFE instance"
  type        = string
}
