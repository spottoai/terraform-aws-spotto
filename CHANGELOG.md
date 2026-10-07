# Changelog

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
