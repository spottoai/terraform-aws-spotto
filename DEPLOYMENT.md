Status: living
Last updated: 2026-10-06
Owner: Platform

# Usage & Deployment

## Requirements
- Terraform >= 1.12.0
- `hashicorp/aws` provider >= 5.0, < 7.0

## Module usage
See `README.md` and `examples/` for module configuration and onboarding workflows.
Customers reference modules with a repository subdirectory source, for example
`git::https://github.com/spottoai/terraform-aws-spotto.git//modules/account-role?ref=<tag>`.

## Verification
Run `terraform init -backend=false && terraform test` in `modules/setup-package`,
`modules/account-role`, `modules/handoff` and `examples/organization`. Tests use
mocked AWS providers and never contact AWS. Regenerate the fixture with
`tests/fixtures/generate-fixture.ts` when the API bundle builder changes.

## State management
Use a remote backend with encryption and access controls. State contains the company
External ID inside the role trust policy, but no AWS credentials.

## Release workflow
Follow the standard process in `../core/DEPLOYMENT.md` unless a repo-specific exception
is documented above. Tag releases so customers can pin `?ref=<tag>`.
