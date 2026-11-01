# Assisted connection in Terraform AWS

Type: repo
Status: living
Owner: Platform
Last updated: 2026-10-26
Core feature: [Assisted connection](../../../../core/specs/cloud-accounts/connections/assisted-connection/assisted-connection.md)

## Boundary

The module deploys hosted CloudFormation templates; it never duplicates IAM or
export policy construction in HCL. The API generator owns policies and generic
artifacts, public spotto-tools publishes them, and customer-approved CloudFormation
owns resources. See the [AWS solution](../../../../core/specs/cloud-accounts/connections/assisted-connection/assisted-connection-aws.md).

## Regional behavior

Required inputs `deployment` and `registration_topic_arn` come from the owning Portal.
They must match exactly. AU/dev AU use Sydney ap-southeast-2, US uses N. Virginia
us-east-1, EU uses Stockholm eu-north-1. Dev/prod are different boundaries. Default
role, stack, bucket and export names include deployment, preventing default
collisions in a shared AWS account. Custom role names remain explicit and stable.

The connect stack creates regional access/storage and registers only with its owning
API. A separate native definition-only stack in us-east-1 is created for new billing,
after regional storage/policy is ready. Its deployment/destination rule and derived
same-account bucket/export names prevent an independent destination override. It has
no External ID, registration callback or customer compute runtime.

Existing-export mode deploys regional exact-prefix billing access and no new export.
Source location remains explicit and is never silently migrated. Selected member
accounts use the regional service-managed StackSet. Customer IAM/data-plane read
exclusions remain the generator's responsibility.

## Contracts and lifecycle

Inputs also include `external_id`, `trusted_principal_arn`, `cost_data`,
`existing_export`, `connect_member_accounts`, `organizational_unit_ids`, `role_name`,
`repair_token` and optional `template_base_url`. Billing is required: choose new
CreateExport or a supported existing source; None is not a new-connection choice.
The module pins a reviewed versioned five-template release and uses AWS provider
v6 per-resource region arguments rather than a US registration default.

Outputs include role ARN, billing bucket and export ARN, regional connect/access/member
stack IDs, global billing-definition stack ID and onboarding region. Parameter and
output names match the generated templates. New bucket, delivery policy and export
are retained on deletion. Removing a stack does not erase data or necessarily stop
export delivery. Explicit retained-source repair must preserve owner/location/prefix.

## Verification and delivery boundary

Mocked-provider tests cover region/topic pairing, regional storage with global export
control, naming, source selection, exact stack parameters, outputs and rejection before
apply. Module and example formatting/validation are required. Template publication,
confirmed regional subscriptions and live create/update/delete evidence remain
separate from source and mocked tests. No production or strict residency claim is
established by a Terraform plan alone.
