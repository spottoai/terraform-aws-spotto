output "account_id" {
  description = "AWS account ID configured by this module instance."
  value       = var.account_id
}

output "role_arn" {
  description = "ARN of SpottoReadOnlyRole."
  value       = aws_iam_role.spotto.arn
}

output "role_name" {
  description = "Name of the Spotto role."
  value       = aws_iam_role.spotto.name
}

output "role_purposes" {
  description = "Spotto purposes this role was configured for."
  value       = try(local.role.role_purposes, [])
}

output "inline_policy_names" {
  description = "Spotto inline policies managed on the role."
  value       = sort(keys(local.inline_policies))
}

output "managed_policy_arns" {
  description = "AWS managed policies attached by the module."
  value       = local.managed_policy_arns
}

output "handoff_result" {
  description = "This account's entry for the portal handoff. Pass every account's value to the handoff module."
  value = {
    accountId = var.account_id
    roleArn   = aws_iam_role.spotto.arn
    status    = "configured"
  }

  # The result reports IAM configuration only after every Spotto policy is in place.
  depends_on = [aws_iam_role_policy.spotto, aws_iam_role_policy_attachment.managed]
}
