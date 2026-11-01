# terraform-aws-spotto

Terraform module that connects an AWS account or organization to Spotto.

It deploys the same hosted CloudFormation templates as the portal's **Launch Stack in
AWS** button and the CloudShell command. CloudFormation owns the read-only role, its
policies and the billing export; this module only creates the stacks, so every route
produces the same role.

| Stack | When | What it creates |
|---|---|---|
| `SpottoConnect-<deployment>` | always | `SpottoReadOnlyRole` with the AWS managed `ViewOnlyAccess` and `SecurityAudit` policies plus the inline `SpottoReadOnlyAccess` and `SpottoCommitmentsPlanning` policies. With `cost_data = "CreateExport"` (the default), also the regional `spotto-billing-<account>-<deployment>` bucket and `SpottoBillingExportRead`. |
| `SpottoBillingAccess-<deployment>` | `existing_export` is set | `SpottoExistingBillingExportRead` on the role, scoped to your existing export. |
| `SpottoMemberAccounts-<deployment>` | `connect_member_accounts = true` | A service-managed StackSet that deploys the role to every account under the given root or OUs, including accounts added later. |

Access, storage and member stacks use the mapped deployment region. Only the separate export-definition stack uses **us-east-1**, delivering files to the regional bucket.

## Requirements

- Terraform >= 1.12.0
- `hashicorp/aws` provider >= 6.0, < 7.0
- An administrator session in the management account (or a standalone account).
  CloudFormation uses your session to create the IAM, S3, Data Exports and StackSet
  resources. Never give Spotto administrator credentials.
- For member accounts: trusted access for CloudFormation StackSets turned on in AWS
  Organizations, and Terraform applied from the management account.

## Usage

In the portal, open **Connectors → Cloud Accounts → Create → AWS → Other Ways to Connect →
Terraform** to get your `external_id` and `trusted_principal_arn`. Apply, then return to
the portal: it detects the role automatically.

### Standalone account with a new export

```hcl
provider "aws" {
  region = "us-east-1"
}

module "spotto" {
  source = "git::https://github.com/spottoai/terraform-aws-spotto.git"

  deployment = "dev-au"
  registration_topic_arn = "arn:aws:sns:ap-southeast-2:715809501612:spotto-aws-connect-dev-au"
  external_id           = "spotto-00000000-0000-0000-0000-000000000000"
  trusted_principal_arn = "arn:aws:iam::999988887777:role/example-engine"
}
```

### Organization with member accounts

Apply in the management account. Use the root ID (`r-xxxx`) to cover every account, or
list specific OU IDs.

```hcl
module "spotto" {
  deployment = "dev-au"
  registration_topic_arn = "arn:aws:sns:ap-southeast-2:715809501612:spotto-aws-connect-dev-au"

  source = "git::https://github.com/spottoai/terraform-aws-spotto.git"

  external_id             = "spotto-00000000-0000-0000-0000-000000000000"
  trusted_principal_arn   = "arn:aws:iam::999988887777:role/example-engine"
  connect_member_accounts = true
  organizational_unit_ids = ["r-ab12"]
}
```

Member accounts get the role with `ViewOnlyAccess`, `SecurityAudit` and `SpottoReadOnlyAccess`. Service-managed StackSets
don't deploy to the management account, which gets its role from `SpottoConnect`.

### Existing export

No bucket or export is created (`CostData=None`); the role is granted read access to your
export instead. The export's bucket must be in the account you apply to. Billing is required, and the export must be a CUR 2.0 Parquet export, daily (or hourly), with resource IDs included.

```hcl
module "spotto" {
  deployment = "dev-au"
  registration_topic_arn = "arn:aws:sns:ap-southeast-2:715809501612:spotto-aws-connect-dev-au"

  source = "git::https://github.com/spottoai/terraform-aws-spotto.git"

  external_id           = "spotto-00000000-0000-0000-0000-000000000000"
  trusted_principal_arn = "arn:aws:iam::999988887777:role/example-engine"

  existing_export = {
    export_name = "finance-cur2"
    bucket_name = "example-billing-exports"
    # Optional: the S3 prefix before the export name, and the export's KMS key.
    base_prefix = "exports"
    kms_key_arn = "arn:aws:kms:us-east-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  }
}
```

The export must be CUR 2.0 in Parquet format. A new `spotto-cur2` export delivers its
first files within 24 hours and starts with the current month.

See [`examples/`](examples) for complete configurations.

## Inputs

| Name | Default | Description |
|---|---|---|
| `deployment` | required | Portal deployment binding. |
| `registration_topic_arn` | required | Must match deployment exactly. |
| `external_id` | required | Company External ID, `spotto-<uuid>`. |
| `trusted_principal_arn` | required | IAM user or role ARN allowed to assume the role. |
| `cost_data` | `CreateExport` | Billing is required. `CreateExport` creates the export; leave it unset when `existing_export` is set. `None` is rejected. |
| `existing_export` | `null` | `{ export_name, bucket_name, base_prefix = "", kms_key_arn = "" }`. |
| `connect_member_accounts` | `false` | Deploy the role to member accounts. |
| `organizational_unit_ids` | `[]` | Root or OU IDs. Required when `connect_member_accounts` is true. |
| `role_name` | `SpottoReadOnlyRole` | Role name in every account and deployment. |
| `repair_token` | `""` | Up to 14 digits. Change it to re-apply the role's trust and policies; see [Repair](#repair). |
| `template_base_url` | `https://spotto-aws-onboarding.s3.amazonaws.com/cloudformation/v<version>/` | Base URL of the templates. Defaults to the template version this module release pins. |

## Outputs

| Name | Description |
|---|---|
| `role_arn` | Role ARN in the applied account. |
| `billing_bucket_name` | Created bucket, the existing export's bucket, or `null`. |
| `export_arn` | ARN of the created `spotto-cur2` export, or `null`. |
| `connect_stack_id` | `SpottoConnect` stack ID. |
| `billing_access_stack_id` | `SpottoBillingAccess-<deployment>` stack ID, or `null`. |
| `member_accounts_stack_id` | `SpottoMemberAccounts-<deployment>` stack ID, or `null`. |

## Upgrade

Each module release pins a template version. To upgrade, move to a newer module release
(change `?ref=` if you pin a tag, or run `terraform init -upgrade` for an unpinned
source), then run `terraform apply`. The plan updates each stack in place to the new
versioned template, and the members stack rolls the new role out to every member account.

Leave `template_base_url` unset. Terraform can't see changes behind an unchanged URL, so
pointing it at the unversioned latest path never upgrades anything.

## Repair

If the role or its policies were changed by hand, set `repair_token` to the current epoch
seconds and apply:

```sh
terraform apply -var="repair_token=$(date +%s)"
```

A new token changes every policy document, so CloudFormation re-applies the trust policy
and all inline policies, in this account and (through the StackSet) in every member account. A plain apply doesn't fix this kind of drift, because
CloudFormation compares against the last template, not the live role. Keep the new value
in your configuration so the next apply doesn't change it back.

If the role was deleted, recreate the `SpottoConnect` stack. The billing bucket and the
`spotto-cur2` export are retained when the stack is deleted, so with
`cost_data = "CreateExport"` first point `existing_export` at them, or the new stack
would try to create the same bucket again:

```hcl
existing_export = {
  export_name = "spotto-cur2"
  bucket_name = "spotto-billing-111122223333" # your account ID
  base_prefix = "cur2"
}
```

```sh
terraform apply -replace='module.spotto.aws_cloudformation_stack.connect'
```

## Changes and removal

- **Existing roles:** a role with the same name that these stacks didn't create makes
  `SpottoConnect` fail. Delete the old role first, or set `role_name`.
- **Removal:** `terraform destroy` deletes the stacks and the roles they created,
  including the roles in member accounts. The billing bucket and export are retained.
  Review destroy plans carefully.

## State

State holds the External ID and trusted principal ARN as stack parameters. They aren't
secrets, but the External ID binds the role to your company, so use a remote backend
with encryption and access controls. State never contains AWS credentials.

## Testing

Terraform-native tests use a mocked AWS provider and never contact AWS:

```sh
terraform init -backend=false && terraform test
```

## Limitations

- Commercial `aws` partition only.
- An existing export's bucket must be in the applied account.

## Links

- Spotto AWS onboarding docs: https://docs.spotto.ai/docs/portal/cloud-account-aws/terraform
- Spotto website: https://www.spotto.ai/

## License

See `LICENSE`.

## Regional deployment binding

`deployment` and `registration_topic_arn` are required and come together from Portal.
The module rejects a topic belonging to another deployment. AU/dev AU use Sydney
`ap-southeast-2`, US uses N. Virginia `us-east-1`, EU uses Stockholm `eu-north-1`.
Development and production have distinct resource names and runtime authority.

The default role is `SpottoReadOnlyRole` in every deployment; stack names end in
`-<deployment>`. New CUR storage is `spotto-billing-<account-id>-<deployment>`, with
export `spotto-cur2-<deployment>`. The regional access stack owns the role, bucket,
policy and registration. A separate `SpottoBillingExport-<deployment>` stack creates
only the global AWS export definition in us-east-1 after regional storage is ready.
It has no External ID or SNS callback and derives the destination owner/bucket from
its own AWS account/deployment. Existing-export mode creates no new export.

The module pins template version `2026-10-30.1`; publish that release's five JSON
files before applying. Billing resources are retained. AWS limits CUR 2.0 exports
to five per account; use a supported existing source if capacity is exhausted.
See `DEPLOYMENT.md` for mocked-provider verification and release order.
