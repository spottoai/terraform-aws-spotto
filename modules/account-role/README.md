# account-role

Creates or updates `SpottoReadOnlyRole` in one AWS account from the Spotto setup
package. Use one instance per enabled account, each with that account's AWS provider.

| Input | Type | Default | Description |
| --- | --- | --- | --- |
| `setup_package` | `string` | required | Contents of `spotto-aws-setup.json`, for example `file("./spotto-aws-setup.json")`. |
| `account_id` | `string` | required | 12-digit account ID; the provider must sign in to this account. |
| `permissions_boundary_arn` | `string` | `null` | Optional boundary required by your organization. |
| `tags` | `map(string)` | `{}` | Extra role tags. `SpottoCompanyId` and `SpottoManagedBy` always win. |

| Output | Description |
| --- | --- |
| `role_arn`, `role_name`, `account_id` | The configured role. |
| `role_purposes` | Spotto purposes from the package. |
| `inline_policy_names` | Spotto inline policies managed on the role. |
| `managed_policy_arns` | Attached AWS managed policies. |
| `handoff_result` | This account's entry for the `handoff` module. |

The plan fails before any change if the provider is signed in to another account,
if the account isn't an enabled account in the package, or if the partition isn't
`aws`. Policies are passed through unchanged from the package; only
`SpottoGuardrails`, `SpottoBillingExportRead` and `SpottoCommitmentsPlanning` are
managed as inline policies. Current packages include discovery permissions in
`SpottoGuardrails` and attach no managed policies. Legacy packages may request
`SecurityAudit` and `ReadOnlyAccess`; guardrails are put in place before those
attachments. No other managed policy ARNs are accepted.
