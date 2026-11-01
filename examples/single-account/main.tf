# One standalone account with a new CUR 2.0 billing export (CostData=CreateExport).

variable "external_id" {
  description = "Company External ID from the portal (Other Ways to Connect > Terraform)."
  type        = string
}

variable "trusted_principal_arn" {
  description = "Trusted principal ARN from the portal (Other Ways to Connect > Terraform)."
  type        = string
}

variable "aws_profile" {
  description = "Optional AWS CLI profile. Leave null to use the default credential chain."
  type        = string
  default     = null
}

module "spotto" {
  deployment             = var.deployment
  registration_topic_arn = var.registration_topic_arn
  source                 = "../../"

  external_id           = var.external_id
  trusted_principal_arn = var.trusted_principal_arn
}

output "role_arn" {
  value = module.spotto.role_arn
}

output "billing_bucket_name" {
  value = module.spotto.billing_bucket_name
}

variable "deployment" { type = string }
variable "registration_topic_arn" { type = string }
