# handoff

Builds the portal results JSON (`kind: spotto.aws.manual-onboarding`, schema version 1)
from the setup package and every account's `account-role.handoff_result`. Paste
`aws_manual_onboarding_json` into Spotto, then use Create/Update for live validation.

| Input | Type | Description |
| --- | --- | --- |
| `setup_package` | `string` | The same package used by every `account-role` instance. |
| `account_results` | `list(object)` | One `handoff_result` per enabled package account. |

| Output | Description |
| --- | --- |
| `aws_manual_onboarding_json` | Portal handoff. Contains no credentials or External ID. |
| `all_configured` | Whether every account result is `configured`. |

The plan fails if any account is missing, duplicated, or has a role ARN that doesn't
match the package, or if the result exceeds the portal's 1 MiB limit.
