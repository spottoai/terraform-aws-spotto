# Thin wrapper around the hosted CloudFormation templates. CloudFormation owns the role,
# its policies and the billing export; this module only deploys the stacks. Every stack is
# regional access stack follows deployment; billing definitions use the AWS global control plane.

locals {
  # Template version this module release pins. Bump it with every template release.
  # Must equal Metadata.TemplateVersion of the generated templates (AWS_CONNECT_TEMPLATE_VERSION in api).
  template_version  = "2026-10-30.1"
  template_base_url = coalesce(var.template_base_url, "https://spotto-aws-onboarding.s3.amazonaws.com/cloudformation/v${local.template_version}/")

  regions     = { dev-au = "ap-southeast-2", prod-au = "ap-southeast-2", prod-us = "us-east-1", prod-eu = "eu-north-1" }
  region      = local.regions[var.deployment]
  # The role name is the same in every deployment; stacks and billing resources carry the deployment.
  role_name   = coalesce(var.role_name, "SpottoReadOnlyRole")
  export_name = "spotto-cur2-${var.deployment}"
  cost_data   = var.existing_export != null ? "None" : coalesce(var.cost_data, "CreateExport")

  templates = {
    connect        = "${local.template_base_url}spotto-aws-connect.template.json"
    billing_export = "${local.template_base_url}spotto-aws-billing-export.template.json"
    billing_access = "${local.template_base_url}spotto-aws-billing-access.template.json"
    members        = "${local.template_base_url}spotto-aws-members.template.json"
  }
}

resource "aws_cloudformation_stack" "connect" {
  region       = local.region
  name         = "SpottoConnect-${var.deployment}"
  template_url = local.templates.connect
  capabilities = ["CAPABILITY_NAMED_IAM"]

  parameters = {
    ExternalId           = var.external_id
    TrustedPrincipalArn  = var.trusted_principal_arn
    CostData             = local.cost_data
    RoleName             = local.role_name
    Deployment           = var.deployment
    RegistrationTopicArn = var.registration_topic_arn
    BillingExportName    = local.export_name
    RepairToken          = var.repair_token
  }
}

# AWS only offers the export definition control plane in us-east-1. The files
# go directly to the regional bucket; this stack has no registration or External ID.
resource "aws_cloudformation_stack" "billing_export" {
  count        = local.cost_data == "CreateExport" ? 1 : 0
  region       = "us-east-1"
  name         = "SpottoBillingExport-${var.deployment}"
  template_url = local.templates.billing_export
  parameters = {
    Deployment   = var.deployment
    BucketRegion = local.region
  }
  depends_on = [aws_cloudformation_stack.connect]
}

resource "aws_cloudformation_stack" "billing_access" {
  count = var.existing_export != null ? 1 : 0

  region       = local.region
  name         = "SpottoBillingAccess-${var.deployment}"
  template_url = local.templates.billing_access
  capabilities = ["CAPABILITY_NAMED_IAM"]

  parameters = {
    RoleName    = local.role_name
    ExportName  = var.existing_export.export_name
    BucketName  = var.existing_export.bucket_name
    BasePrefix  = var.existing_export.base_prefix
    KmsKeyArn   = var.existing_export.kms_key_arn
    RepairToken = var.repair_token
  }

  # The policy is added to the role that SpottoConnect creates.
  depends_on = [aws_cloudformation_stack.connect]
}

resource "aws_cloudformation_stack" "member_accounts" {
  count = var.connect_member_accounts ? 1 : 0

  region       = local.region
  name         = "SpottoMemberAccounts-${var.deployment}"
  template_url = local.templates.members
  capabilities = ["CAPABILITY_NAMED_IAM"]

  parameters = {
    ExternalId            = var.external_id
    TrustedPrincipalArn   = var.trusted_principal_arn
    OrganizationalUnitIds = join(",", var.organizational_unit_ids)
    RoleName              = local.role_name
    RepairToken           = var.repair_token
  }

  # The StackSet deploys to every account under the OUs, which can take a while.
  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }

  depends_on = [aws_cloudformation_stack.connect]
}
