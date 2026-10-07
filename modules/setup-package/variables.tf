variable "setup_package" {
  description = "Contents of the V1 AWS setup package (spotto-aws-setup.json) downloaded from the Spotto portal, for example file(\"./spotto-aws-setup.json\")."
  type        = string
  nullable    = false

  validation {
    condition     = can(jsondecode(var.setup_package))
    error_message = "setup_package must be the JSON contents of the AWS setup package downloaded from Spotto."
  }

  validation {
    condition     = length(var.setup_package) <= 1048576
    error_message = "setup_package exceeds the 1 MiB setup package limit."
  }
}
