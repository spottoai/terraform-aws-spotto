# Changelog

## 1.0.0 - Unreleased

Breaking change. The module now deploys the hosted CloudFormation templates, so Terraform,
the portal's **Launch Stack in AWS** and the CloudShell command all create the same role.

- The root module is now the module. It creates the `SpottoConnect` stack, plus
  `SpottoBillingAccess` for an existing export and `SpottoMemberAccounts` (a
  service-managed StackSet) for member accounts, all in us-east-1.
- New inputs: `external_id`, `trusted_principal_arn`, `cost_data`, `existing_export`,
  `connect_member_accounts`, `organizational_unit_ids`, `role_name`, `repair_token` and
  `template_base_url`. New outputs: `role_arn`, `billing_bucket_name`, `export_arn` and
  the stack IDs.
- Removed: the setup package input, the results JSON and the `setup-package`,
  `account-role` and `handoff` modules, with their fixtures and tests. There is no
  migration path: AWS isn't in production use. Destroy roles created by 0.x (or delete
  them) before applying 1.0.0.
- The read-only inline policy is now `SpottoReadOnlyAccess`, and the role is tagged
  `SpottoManagedBy=CloudFormation`.
- Template 2026-10-30.1: the role allows 4-hour sessions (`MaxSessionDuration` 14400) so
  long security framework assessment scans keep valid credentials.
- `template_base_url` defaults to the versioned template path this release pins, so an
  upgrade is a module version bump followed by `terraform apply`.
- `repair_token` (passed as `RepairToken`) re-applies the role's trust and inline policies
  when changed. See **Repair** in the README.
- Creates the billing bucket and the `spotto-cur2` CUR 2.0 export
  (`cost_data = "CreateExport"`, the default), or reads `existing_export`. Billing is
  required: `cost_data = "None"` is rejected.
- Requires `hashicorp/aws` >= 6.0, which creates the stacks in us-east-1 regardless of
  the provider Region.

## 0.1.0 - 2026-10-07

- Initial AWS onboarding modules. `account-role` creates or updates `SpottoReadOnlyRole`
  per account from the portal setup package, passing API-authored trust, read-only,
  billing and commitments policies through unchanged, and refuses wrong-account sessions
  before any change. `handoff` produces the portal results JSON (`spotto.aws.manual-onboarding`
  V1) shared with the PowerShell wizard. `setup-package` validates the package with the
  same checks as the wizard.
- Roles are tagged `SpottoManagedBy=Terraform`; the PowerShell wizard verifies such roles
  but never adopts or changes them.
- Terraform-native tests with mocked AWS providers, an API-generated package fixture, and
  single-account and organization examples.

## Regional onboarding

- Require the Portal deployment/topic binding; isolate access, member and billing
  storage stacks by environment/geography.
- Create native global export definitions in a separate us-east-1 stack, targeting
  the regional bucket. Pin the five-template release 2026-10-26.3.
- Namespace default roles, stack names, exports and new buckets by deployment.
