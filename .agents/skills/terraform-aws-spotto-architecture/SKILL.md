---
name: terraform-aws-spotto-architecture
description: Architecture of the Terraform modules that onboard customer AWS accounts and organizations into Spotto (SpottoReadOnlyRole, API-authored policies, portal handoff). Use when changing module inputs or outputs, package validation, role policies, examples, or the Terraform AWS onboarding flow.
---

Status: living
Last updated: 2026-10-16
Owner: Platform
Related docs: README.md, CHANGELOG.md, DEPLOYMENT.md, specs/aws/terraform-aws-spotto-onboarding.md, ../spotto-tools/onboarding/aws/README.md, ../core/specs/onboarding/aws-powershell-onboarding.md

# terraform-aws-spotto-architecture

## Purpose
Defines the architecture of the Terraform modules used to onboard AWS accounts into Spotto.

## Scope
- Covers module structure, package validation, role resources, the portal handoff and examples.
- Excludes the API policy generator, portal UI and engine validation.

## System context
- Upstream: the Spotto portal setup package (`kind: spotto.aws.setup`, V1), authored by the API's
  `AwsIamOnboardingBundleBuilder` and downloaded by a customer administrator.
- Downstream: customer-managed `SpottoReadOnlyRole` per AWS account, and the portal results JSON
  (`kind: spotto.aws.manual-onboarding`, V1) shared with the PowerShell wizard.
- Primary responsibility: apply the API-authored role configuration declaratively.

## Key components
- `modules/setup-package/` - resource-free parser/validator; mirrors `Read-SpottoAwsSetupPackage`.
- `modules/account-role/` - one account's role, Spotto inline policies and managed attachments.
- `modules/handoff/` - portal results JSON covering every package account exactly once.
- `examples/` - single account; organization with split billing storage via assume_role.
- `tests/fixtures/` - API-generated package fixture and its generator.

## Data flow (happy path)
1. Customer configures accounts and billing in Spotto and downloads the setup package.
2. `account-role` instances (one provider per account) validate the package and caller account,
   then apply trust, guardrails, billing/commitments policies and managed policies.
3. `handoff` emits the results JSON; the customer pastes it into Spotto.
4. Spotto Create/Update performs live access validation (engine-owned).

## Integration boundaries & invariants
- Never author IAM permissions here. Policies, trust and External ID come only from the package;
  duplicating the generator caused earlier permission drift.
- Package validation stays aligned with both scripts in `spotto-tools/onboarding/aws/`. Change
  both together, and regenerate the fixture when the API builder changes.
- Billing and commitments policy documents must be present exactly when their role purposes
  are selected, use the documented Spotto policy names, and contain nonempty `Statement`
  arrays. Guardrails also require a nonempty `Statement` array.
- The handoff configuration must round-trip unchanged; the portal compares it to the current draft.
- Manage only `SpottoGuardrails`, `SpottoBillingExportRead`, `SpottoCommitmentsPlanning` and the
  package-requested legacy `SecurityAudit`/`ReadOnlyAccess` attachments; unrelated
  customer policies are untouched. Current packages have no managed policies and
  carry discovery allows inside `SpottoGuardrails`; validation accepts an empty
  list or only the two allowlisted legacy ARNs, matching PowerShell.
- Roles carry `SpottoManagedBy=Terraform`; the PowerShell wizard is verify-only for them.
- Fail the plan before mutation on wrong-account credentials, unknown accounts or a non-`aws` partition.
- Modules reference `../setup-package`; consumers must use repository subdirectory or registry sources.
- Outputs remain backward compatible for existing automation.
