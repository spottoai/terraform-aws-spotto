variable "setup_package" {
  description = "Contents of the V1 AWS setup package (spotto-aws-setup.json) downloaded from the Spotto portal, for example file(\"./spotto-aws-setup.json\")."
  type        = string
  nullable    = false
}

variable "account_id" {
  description = "12-digit AWS account ID this module instance configures. It must be an enabled account in the setup package, and the module's AWS provider must authenticate to it."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "account_id must be a 12-digit AWS account ID string (keep leading zeros)."
  }
}

variable "permissions_boundary_arn" {
  description = "Optional IAM permissions boundary required by your organization. A boundary can deny Spotto reads even when the role policies are correct."
  type        = string
  default     = null

  validation {
    condition     = var.permissions_boundary_arn == null || can(regex("^arn:aws:iam::([0-9]{12}|aws):policy/[A-Za-z0-9+=,.@_/-]{1,512}$", var.permissions_boundary_arn))
    error_message = "permissions_boundary_arn must be an IAM policy ARN in the aws partition."
  }
}

variable "tags" {
  description = "Additional tags for the role. SpottoCompanyId and SpottoManagedBy are always set by the module."
  type        = map(string)
  default     = {}
  nullable    = false
}
