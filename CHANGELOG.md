# Changelog

## Unreleased (planned 0.2.0)

- Accept current API setup packages with an empty `managedPolicies` list and
  discovery permissions in `SpottoGuardrails`. Legacy packages may still request
  the allowlisted `ReadOnlyAccess` and `SecurityAudit` managed policies.
- Applying a current package removes legacy `ReadOnlyAccess`/`SecurityAudit`
  attachments tracked in Terraform state. Unmanaged attachments remain untouched.
  Review the plan and verify Spotto access when migrating from a legacy package.
- Require billing and commitments policies exactly when their role purposes are
  selected, with the documented policy names and nonempty `Statement` arrays.
  Reject missing, unexpected, null and malformed policy documents before applying.
- Add current and legacy API fixture coverage and Terraform-native policy
  validation regressions; document Bash onboarding and **Setup Results JSON**.

## 0.1.0 - 2026-10-07

- Initial AWS onboarding modules. `account-role` creates or updates `SpottoReadOnlyRole`
  per account from the portal setup package, passing API-authored trust, guardrail,
  billing and commitments policies through unchanged, and refuses wrong-account sessions
  before any change. `handoff` produces the portal results JSON (`spotto.aws.manual-onboarding`
  V1) shared with the PowerShell wizard. `setup-package` validates the package with the
  same checks as the wizard.
- Roles are tagged `SpottoManagedBy=Terraform`; the PowerShell wizard verifies such roles
  but never adopts or changes them.
- Terraform-native tests with mocked AWS providers, an API-generated package fixture, and
  single-account and organization examples.
