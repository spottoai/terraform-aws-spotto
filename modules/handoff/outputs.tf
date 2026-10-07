output "aws_manual_onboarding_json" {
  description = "Portal handoff JSON (kind spotto.aws.manual-onboarding). Paste it into the AWS results field in Spotto, then use Create/Update for live validation. Contains no credentials or External ID."
  value       = local.handoff_json

  precondition {
    condition = (
      length(distinct(local.result_account_ids)) == length(local.result_account_ids) &&
      toset(local.result_account_ids) == toset(keys(module.package.roles))
    )
    error_message = "Provide exactly one account result for every enabled account in the setup package. Missing: ${join(", ", setsubtract(keys(module.package.roles), local.result_account_ids))}. Unexpected or duplicate entries are also rejected."
  }

  precondition {
    condition     = alltrue([for result in var.account_results : try(module.package.roles[result.accountId].role_arn == result.roleArn, false)])
    error_message = "Every account result must use the SpottoReadOnlyRole ARN from the setup package."
  }

  precondition {
    condition     = local.handoff_bytes <= 1048576
    error_message = "The handoff exceeds the 1 MiB portal limit."
  }
}

output "all_configured" {
  description = "Whether every account result is configured. Spotto Create/Update still performs live access validation."
  value       = alltrue([for result in var.account_results : result.status == "configured"])
}
