Status: living
Last updated: 2026-10-26
Owner: Platform

# Usage & Deployment

## Requirements
- Terraform >= 1.12.0
- `hashicorp/aws` provider >= 6.0, < 7.0

## Module usage
See `README.md` and `examples/` for module configuration. Customers reference the root
module, for example `git::https://github.com/spottoai/terraform-aws-spotto.git`.
Sources are unpinned: customers always use the latest `main`, so keep `main` releasable.

The module deploys the hosted CloudFormation templates from the versioned path
`https://spotto-aws-onboarding.s3.amazonaws.com/cloudformation/v<TemplateVersion>/`. The
templates are generated in the api repo and published from `spotto-tools`; change them
there, not here. Every template release needs a module release that bumps
`local.template_version` in `main.tf` to the templates' `Metadata.TemplateVersion`.
Keep stack names, parameter names and outputs aligned with
`../core/specs/cloud-accounts/connections/assisted-connection/assisted-connection-aws.md`.

## Verification
Run `terraform fmt -check -recursive`, then `terraform init -backend=false`,
`terraform validate` and `terraform test` in the repository root, and `terraform
validate` in each `examples/` folder. Tests use a mocked AWS provider and never contact AWS.

## State management
Use a remote backend with encryption and access controls. State contains the company
External ID as a stack parameter, but no AWS credentials.

## Release workflow
Follow the standard process in `../core/DEPLOYMENT.md` unless a repo-specific exception
is documented above. Customer docs do not pin a version; changes on `main` reach customers
on their next `terraform init -upgrade`.

## Regional release contract

Publish all five versioned templates before this module release. Inputs `deployment`
and `registration_topic_arn` must match the owning API. The default role and all
stack/bucket/export names are deployment-scoped. Access/storage/member stacks use
Sydney, N. Virginia or Stockholm; only the export-definition stack uses us-east-1.
Its `BucketRegion` remains the owning geography. No AWS runtime or API deploy occurs
from Terraform. Validate dev AU creation, updates, retained-data repair and deletion,
then each production geography; keep the owning callback API available for lifecycle.
