# The management account gets the role and a new billing export. A service-managed StackSet
# then deploys the role to every account under the root or OUs, including accounts added later.

variable "external_id" {
  description = "Company External ID from the portal (Other Ways to Connect > Terraform)."
  type        = string
}

variable "trusted_principal_arn" {
  description = "Trusted principal ARN from the portal (Other Ways to Connect > Terraform)."
  type        = string
}

variable "organizational_unit_ids" {
  description = "Organization root ID (r-xxxx) to cover every account, or specific OU IDs."
  type        = list(string)
}

variable "aws_profile" {
  description = "Optional AWS CLI profile for the management account. Leave null to use the default credential chain."
  type        = string
  default     = null
}

module "spotto" {
  deployment             = var.deployment
  registration_topic_arn = var.registration_topic_arn
  source                 = "../../"

  external_id             = var.external_id
  trusted_principal_arn   = var.trusted_principal_arn
  connect_member_accounts = true
  organizational_unit_ids = var.organizational_unit_ids
}

output "role_arn" {
  value = module.spotto.role_arn
}

output "billing_bucket_name" {
  value = module.spotto.billing_bucket_name
}

output "member_accounts_stack_id" {
  value = module.spotto.member_accounts_stack_id
}

variable "deployment" { type = string }
variable "registration_topic_arn" { type = string }
