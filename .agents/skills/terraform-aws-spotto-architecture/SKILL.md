---
name: terraform-aws-spotto-architecture
description: Architecture of the Terraform module that connects customer AWS accounts and organizations to Spotto by deploying the hosted CloudFormation templates (SpottoConnect, SpottoBillingAccess, SpottoMemberAccounts). Use when changing module inputs or outputs, stack parameters, examples, or the Terraform AWS onboarding flow.
---

Status: living
Last updated: 2026-10-22
Owner: Platform
Related docs: README.md, CHANGELOG.md, DEPLOYMENT.md, specs/cloud-accounts/assisted-connection/assisted-connection-terraform-aws-spotto.md, ../core/specs/cloud-accounts/connections/assisted-connection/assisted-connection-aws.md

# terraform-aws-spotto-architecture

## Purpose
Defines the architecture of the Terraform module used to connect AWS accounts to Spotto.

## Scope
- Covers the root module, its stacks, inputs, outputs, tests and examples.
- Excludes the CloudFormation templates (generated in api, published from spotto-tools),
  the portal UI and the connect API.

## System context
- Upstream: the hosted templates at `https://spotto-aws-onboarding.s3.amazonaws.com/cloudformation/v<TemplateVersion>/`
  (`spotto-aws-connect`, `spotto-aws-billing-access`, `spotto-aws-members`), plus the
  company External ID and trusted principal ARN shown in the portal.
- Downstream: CloudFormation stacks in the customer's management or standalone account,
  which create `SpottoReadOnlyRole`, its policies, the optional billing bucket and export,
  and the member-account StackSet. The portal detects the role through `connect/check`.

## Key components
- `main.tf` - regional access/member/billing-access stacks plus a separate definition-only
  us-east-1 stack. The provider v6 `region` argument selects each stack region.
- `variables.tf` - inputs and their format and combination checks.
- `outputs.tf` - role ARN, billing bucket, export ARN and stack IDs.
- `tests/` - mocked-provider `terraform test` files.
- `examples/` - standalone account; organization with member accounts.

## Integration boundaries & invariants
- Never author IAM, S3 or export resources here. CloudFormation is the single source of
  truth for the role; the scripts, portal and Terraform deploy the same templates.
- Stack names (`SpottoConnect`, `SpottoBillingAccess`, `SpottoMemberAccounts`), parameter
  names and output names must match the templates and the core spec.
- `existing_export` forces `CostData=None`; an explicit `cost_data = "CreateExport"` with
  it is rejected. Billing is required, so `cost_data = "None"` is rejected too.
- `local.template_version` pins the template version; each template release needs a module
  release that bumps it. Terraform can't detect changes behind an unchanged URL.
- `repair_token` maps to `RepairToken` on the connect stack only; the members template has
  no such parameter yet.
- Commercial `aws` partition only.
