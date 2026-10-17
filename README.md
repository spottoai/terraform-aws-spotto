# terraform-aws-spotto

Terraform modules for onboarding AWS accounts and organizations into Spotto.

This is the Terraform route for the same onboarding flow as the
[Bash and PowerShell scripts](https://github.com/spottoai/spotto-tools/tree/main/onboarding/aws).
All consume the **setup package** (`spotto-aws-setup.json`) that you download from
the Spotto portal and produce the same results JSON, which you paste back into Spotto.

The modules never write IAM permissions of their own. The trust policy, the company
External ID, the guardrails, and the billing and commitments policies are all
generated for your company by the Spotto API and passed through unchanged. When
Spotto's required permissions change, download a new package and run `terraform
apply`; Terraform changes only what differs.

## Modules

- `modules/account-role`: creates or updates `SpottoReadOnlyRole` in **one** AWS
  account. Use one instance per enabled account, each with an AWS provider for that
  account. The module:
  - sets the API-authored trust policy;
  - adds the `SpottoGuardrails` inline policy, plus `SpottoBillingExportRead` and
    `SpottoCommitmentsPlanning` when the account's purposes need them;
  - attaches only the managed policies requested by the package (current packages
    use inline discovery permissions; legacy packages may request `SecurityAudit`
    and `ReadOnlyAccess`);
  - tags the role `SpottoCompanyId=<company>` and `SpottoManagedBy=Terraform`.

  Before any change, it checks that the provider is signed in to the expected account.
- `modules/handoff`: builds the portal results JSON from every account's
  `handoff_result`, and fails the plan if any package account is missing or doesn't match.
- `modules/setup-package`: parses and validates the package, and is used by the other
  two modules. It has no resources and validates the same package contract as the onboarding scripts.

## Requirements

- Terraform >= 1.12.0
- `hashicorp/aws` provider >= 5.0, < 7.0 (tested with 5.100 and 6.67)
- An AWS session for each target account, from a customer administrator. Never give
  Spotto administrator credentials.

### Permissions for the applying identity (per account)

- `sts:GetCallerIdentity`
- `iam:GetRole`, `iam:CreateRole`, `iam:UpdateAssumeRolePolicy`, `iam:TagRole`,
  `iam:UntagRole`, `iam:ListRoleTags`, `iam:UpdateRole`, `iam:DeleteRole`
- `iam:GetRolePolicy`, `iam:PutRolePolicy`, `iam:DeleteRolePolicy`, `iam:ListRolePolicies`
- `iam:ListAttachedRolePolicies`, `iam:AttachRolePolicy`, `iam:DetachRolePolicy`
- `iam:ListInstanceProfilesForRole` (read by the AWS provider when the role is deleted)
- `iam:PutRolePermissionsBoundary` when you set `permissions_boundary_arn`

## Workflow

1. In Spotto, open **Connectors → Cloud Accounts → Create → AWS**. Add the account or
   organization and every account Spotto should cover. Billing is optional; see
   [Billing exports](#billing-exports).
2. On the **Deploy Access** step, choose **Bash, PowerShell or Terraform**, then select
   **Download Setup Package**. Review its trust and permission policies, then save it next to your Terraform configuration.
3. Run `terraform init` and `terraform plan`. The plan stops with an explicit error
   if a provider is signed in to the wrong account, an account isn't in the package,
   or the package was edited or isn't for AWS.
4. Run `terraform apply`, then `terraform output -raw aws_manual_onboarding_json`.
5. In Spotto, paste the JSON into **Setup Results JSON** and choose **Read Setup
   Results**. Then choose **Create** or **Update**. Spotto then checks live that it can assume each role, read resources
   and reach the billing export.

`configured` in the handoff means the IAM setup completed. It doesn't prove Spotto
has effective access: service control policies, permissions boundaries, S3 bucket
policies and KMS key policies can still deny it.

## Quickstart: one account

```hcl
provider "aws" {
  region = "us-east-1" # IAM is global; this only selects the STS endpoint.
}

locals {
  setup_package = file("./spotto-aws-setup.json")
}

module "spotto_role" {
  source = "git::https://github.com/spottoai/terraform-aws-spotto.git//modules/account-role"

  setup_package = local.setup_package
  account_id    = "111122223333"
}

module "spotto_handoff" {
  source = "git::https://github.com/spottoai/terraform-aws-spotto.git//modules/handoff"

  setup_package   = local.setup_package
  account_results = [module.spotto_role.handoff_result]
}

output "aws_manual_onboarding_json" {
  value = module.spotto_handoff.aws_manual_onboarding_json
}
```

The examples always use the latest version from `main`. Run `terraform init -upgrade`
to pick up module updates. Reference the modules from the repository root with a
`//modules/...` subdirectory, as shown. They share `modules/setup-package` by relative
path, so you can't copy one module directory on its own, or point at it with an
absolute local path.

## Organizations and multiple accounts

Terraform needs one AWS provider per account, so each enabled account gets its own
module instance with `providers = { aws = aws.<alias> }`.
`examples/organization` signs in to the management account and assumes
`OrganizationAccountAccessRole` (or `AWSControlTowerExecution`) in member
accounts. You can also give each provider its own IAM Identity Center profile.

Spotto doesn't discover organization accounts: the package covers exactly the
accounts you listed in the portal. The handoff module fails the plan until every one
of them has a module instance. Signing in to the management account doesn't give
you IAM administration in member accounts.

## Billing exports

These modules reuse existing AWS Data Exports or Cost and Usage Reports. They don't
create exports, S3 buckets or KMS keys. The definition account and the storage
account may be different accounts. The module grants each one only the scope its
role needs:

- the definition role gets `bcm-data-exports:GetExport` for the exact export ARN;
- the storage role gets S3 reads on the export's delivery path, plus `kms:Decrypt`
  when the export uses a KMS key.

If you know the export details, enter them in Spotto and apply once. To find the
export with **Discover exports** instead, the role must exist first, and the setup
package can't carry the first-pass discovery policy:

1. Leave billing sources empty and apply a discovery-only package.
2. Add the billing source in Spotto. For the export definition account, generate the
   role instructions and add the first-pass `SpottoBillingExportRead` inline policy to
   the role in IAM. It can only list exports.
3. Discover and choose the export, regenerate the role instructions, replace
   `SpottoBillingExportRead` with the exact-export policy, then validate the export
   destination.
4. Download a new package and apply again. Terraform takes over
   `SpottoBillingExportRead` and applies the remaining billing policies.

Before applying to an account whose billing reads already work, check the
`SpottoGuardrails` scope in the package. Its `DenyS3ObjectReadsOutsideBillingScopes`
statement denies object reads outside `<basePrefix>/<exportName>/*`. If you entered
the delivery path, rather than the base prefix, as the base prefix in Spotto, that
deny blocks the real export data.

## Existing roles

`SpottoReadOnlyRole` might already exist, for example from the manual instructions,
the Bash script, PowerShell wizard or a previous tool. If you apply without importing it, the
apply fails with `EntityAlreadyExists`; the role is never adopted silently. To bring
it under Terraform, add import blocks to your root module and review the plan:

```hcl
import {
  to = module.spotto_role.aws_iam_role.spotto
  id = "SpottoReadOnlyRole"
}

import {
  to = module.spotto_role.aws_iam_role_policy.spotto["SpottoGuardrails"]
  id = "SpottoReadOnlyRole:SpottoGuardrails"
}

import {
  to = module.spotto_role.aws_iam_role_policy_attachment.managed["arn:aws:iam::aws:policy/ReadOnlyAccess"]
  id = "SpottoReadOnlyRole/arn:aws:iam::aws:policy/ReadOnlyAccess"
}
```

The managed attachment import above applies to legacy packages only. Import the
other Spotto inline policies and any package-requested managed attachments the
same way. The plan then shows the exact trust, policy and tag changes, including
the switch to `SpottoManagedBy=Terraform`.

Terraform manages only the role, the three Spotto inline policy names and any
package-requested legacy `SecurityAudit`/`ReadOnlyAccess` attachments. Applying a
current package removes legacy attachments already tracked in Terraform state;
untracked attachments remain untouched. Other customer inline or managed policies
on the role are left alone. Don't import a role that a CloudFormation stack owns;
update that stack instead.

## Coexistence with the Bash and PowerShell scripts

Both scripts treat a role tagged `SpottoManagedBy=Terraform` as verify-only:

- If the role matches the package, `-CheckOnly` reports `configuration-matches`, and
  configure mode reports `configured` without writing anything.
- If it drifts, the wizard lists the differences and refuses to change the role, even
  with `-RepairExistingRole`. Apply the fix with Terraform.

For Bash, use `--check-only` and `--repair-existing-role` instead of the PowerShell
switches. Get the [Bash script and usage guide](https://github.com/spottoai/spotto-tools/tree/main/onboarding/aws)
or read the [Bash onboarding documentation](https://docs.spotto.ai/docs/portal/cloud-account-aws/bash).

This means only one tool ever writes to the role.

## Changes and removal

- **New package:** applying a new package changes only what differs.
- **Purpose removed in Spotto:** the matching Spotto inline policy is deleted on the
  next apply.
- **Account removed:** removing an account's module instance, or running `terraform
  destroy`, **deletes** that account's `SpottoReadOnlyRole`. The PowerShell wizard
  never deletes roles. Review destroy plans carefully.
- **Permissions boundary:** set `permissions_boundary_arn` when your organization
  requires one. A boundary or SCP can still deny Spotto reads, and an IAM `Allow`
  can't override an explicit deny.

## State

The setup package and state contain the company External ID inside the trust
policy. AWS doesn't treat an External ID as a secret, but it binds the role to your
Spotto company, so use a remote backend with encryption and access controls. Neither
the setup package, the state nor the handoff contains AWS credentials. The handoff
output also contains no External ID.

## Outputs

`account-role`: `account_id`, `role_arn`, `role_name`, `role_purposes`,
`inline_policy_names`, `managed_policy_arns`, `handoff_result`.

`handoff`: `aws_manual_onboarding_json` (portal results JSON), `all_configured`.

## Testing

Each module and the organization example has Terraform-native tests that use mocked
AWS providers and never contact AWS:

```sh
for dir in modules/setup-package modules/account-role modules/handoff examples/organization; do
  (cd "$dir" && terraform init -backend=false && terraform test)
done
```

The fixtures preserve both legacy managed-policy packages and current inline
discovery packages generated by the real API bundle builder. See
[`tests/fixtures/README.md`](tests/fixtures/README.md) for provenance and regeneration.
Package validation requires billing and commitments policies exactly when their
role purposes are selected, with the documented names and nonempty `Statement`
arrays. Native regressions cover missing, unexpected and malformed policies.
See [CHANGELOG.md](CHANGELOG.md) for the planned 0.2.0 release and legacy attachment
migration behavior.

## Limitations

- Commercial `aws` partition only, matching the Spotto API.
- No creation of billing exports, StackSets, AWS accounts or security services.
- Terraform providers can't be generated per account, so every account needs a
  provider block of its own.

## Links

- Spotto AWS onboarding docs: https://docs.spotto.ai/docs/portal/cloud-account-aws/terraform
- Spotto website: https://www.spotto.ai/

## License

See `LICENSE`.
