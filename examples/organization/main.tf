# One account-role module per enabled account in the setup package. Every package account
# must appear in the handoff; plan fails with the missing account IDs otherwise.

variable "setup_package_path" {
  description = "Path to spotto-aws-setup.json downloaded from Spotto (Connectors > Cloud Accounts > AWS > Download setup package)."
  type        = string
  default     = "./spotto-aws-setup.json"
}

variable "management_account_id" {
  description = "Management (payer) account. In this example it holds the billing export definition and commitments planning."
  type        = string
}

variable "billing_storage_account_id" {
  description = "Account that owns the S3 bucket receiving the billing export."
  type        = string
}

variable "workload_account_id" {
  description = "Member account with resource discovery only."
  type        = string
}

variable "member_admin_role_name" {
  description = "Administrator role assumed in member accounts, such as OrganizationAccountAccessRole or AWSControlTowerExecution."
  type        = string
  default     = "OrganizationAccountAccessRole"
}

variable "aws_profile" {
  description = "Optional AWS CLI profile for the management account session. Leave null to use the default credential chain."
  type        = string
  default     = null
}

locals {
  setup_package = file(var.setup_package_path)
}

module "spotto_management" {
  source = "../../modules/account-role"

  setup_package = local.setup_package
  account_id    = var.management_account_id
}

module "spotto_billing_storage" {
  source    = "../../modules/account-role"
  providers = { aws = aws.billing_storage }

  setup_package = local.setup_package
  account_id    = var.billing_storage_account_id
}

module "spotto_workload" {
  source    = "../../modules/account-role"
  providers = { aws = aws.workload }

  setup_package = local.setup_package
  account_id    = var.workload_account_id
}

module "spotto_handoff" {
  source = "../../modules/handoff"

  setup_package = local.setup_package
  account_results = [
    module.spotto_management.handoff_result,
    module.spotto_billing_storage.handoff_result,
    module.spotto_workload.handoff_result,
  ]
}

output "role_arns" {
  value = {
    (var.management_account_id)      = module.spotto_management.role_arn
    (var.billing_storage_account_id) = module.spotto_billing_storage.role_arn
    (var.workload_account_id)        = module.spotto_workload.role_arn
  }
}

# terraform output -raw aws_manual_onboarding_json, then paste it into Spotto.
output "aws_manual_onboarding_json" {
  value = module.spotto_handoff.aws_manual_onboarding_json
}
