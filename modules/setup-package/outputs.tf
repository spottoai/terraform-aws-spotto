output "roles" {
  description = "Validated per-account role definitions keyed by 12-digit account ID: role ARN, purposes, trust policy JSON, Spotto inline policy JSON by name, and AWS managed policy ARNs."
  value       = local.roles

  precondition {
    condition     = local.package_header_valid
    error_message = "Use a V1 AWS setup package downloaded from Spotto (kind spotto.aws.setup, schemaVersion 1)."
  }

  precondition {
    condition     = local.schema_versions_valid
    error_message = "Every schemaVersion in the setup package must be the number 1, not a string or boolean."
  }

  precondition {
    condition     = local.configuration_valid
    error_message = "The setup package configuration is not a valid AWS configuration bound to company ${local.company_id}."
  }

  precondition {
    condition     = local.configuration_credential_free
    error_message = "The setup package configuration must not contain credentials or an External ID."
  }

  precondition {
    condition     = local.roles_cover_configuration
    error_message = "The setup package must cover 1-100 enabled AWS accounts exactly once. Download a new package from Spotto."
  }

  precondition {
    condition     = alltrue([for check in local.role_checks : check.binding])
    error_message = "Account IDs and standard SpottoReadOnlyRole ARNs must match the configuration for: ${join(", ", [for check in local.role_checks : check.account_id if !check.binding])}."
  }

  precondition {
    condition     = alltrue([for check in local.role_checks : check.purposes])
    error_message = "Role purposes do not match the active configuration (resource-discovery is required) for: ${join(", ", [for check in local.role_checks : check.account_id if !check.purposes])}."
  }

  precondition {
    condition     = alltrue([for check in local.role_checks : check.trust])
    error_message = "The trust policy must require the exact Spotto principal and the company External ID shared by every role. Invalid for: ${join(", ", [for check in local.role_checks : check.account_id if !check.trust])}."
  }

  precondition {
    condition     = alltrue([for check in local.role_checks : check.policies])
    error_message = "Spotto guardrails, the SecurityAudit/ReadOnlyAccess managed policies and the documented Spotto policy names are required. Invalid for: ${join(", ", [for check in local.role_checks : check.account_id if !check.policies])}."
  }
}

output "company_id" {
  description = "Spotto company ID the package is bound to."
  value       = local.company_id
}

output "configuration" {
  description = "The unchanged AWS configuration manifest from the package, echoed into the portal handoff."
  value       = local.configuration
}

output "account_ids" {
  description = "Enabled AWS account IDs covered by the package."
  value       = sort(local.role_account_ids)
}

output "trusted_principal_arn" {
  description = "Spotto principal trusted by every role."
  value       = local.trusted_principal_arn
}
