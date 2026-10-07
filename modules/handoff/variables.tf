variable "setup_package" {
  description = "Contents of the same V1 AWS setup package used by every account-role module."
  type        = string
  nullable    = false
}

variable "account_results" {
  description = "handoff_result output from every account-role module instance, exactly one per enabled account in the package."
  type = list(object({
    accountId = string
    roleArn   = string
    status    = string
  }))
  nullable = false

  validation {
    condition     = alltrue([for result in var.account_results : contains(["configured", "configuration-matches", "changes-required", "planned", "failed"], result.status)])
    error_message = "Each account result status must be one the Spotto portal accepts."
  }
}
