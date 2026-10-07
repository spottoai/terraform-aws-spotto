variable "setup_package_path" {
  description = "Path to spotto-aws-setup.json downloaded from Spotto (Connectors > Cloud Accounts > AWS > Download PowerShell setup package)."
  type        = string
  default     = "./spotto-aws-setup.json"
}

variable "account_id" {
  description = "12-digit AWS account ID to configure. The provider must authenticate to this account."
  type        = string
}

variable "aws_profile" {
  description = "Optional AWS CLI profile. Leave null to use the default credential chain."
  type        = string
  default     = null
}

locals {
  setup_package = file(var.setup_package_path)
}

module "spotto_role" {
  source = "../../modules/account-role"

  setup_package = local.setup_package
  account_id    = var.account_id
}

module "spotto_handoff" {
  source = "../../modules/handoff"

  setup_package   = local.setup_package
  account_results = [module.spotto_role.handoff_result]
}

output "role_arn" {
  value = module.spotto_role.role_arn
}

# terraform output -raw aws_manual_onboarding_json, then paste it into Spotto.
output "aws_manual_onboarding_json" {
  value = module.spotto_handoff.aws_manual_onboarding_json
}
