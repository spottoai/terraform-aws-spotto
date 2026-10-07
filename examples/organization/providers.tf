# The default provider signs in to the management (payer) account. Member accounts are reached
# by assuming an administrator role that AWS Organizations or Control Tower created in each
# account (OrganizationAccountAccessRole or AWSControlTowerExecution). You can instead give
# each provider its own profile, for example an IAM Identity Center permission set per account.
# IAM is global; the Region only selects the STS endpoint.
provider "aws" {
  region  = "us-east-1"
  profile = var.aws_profile
}

provider "aws" {
  alias   = "billing_storage"
  region  = "us-east-1"
  profile = var.aws_profile

  assume_role {
    role_arn     = "arn:aws:iam::${var.billing_storage_account_id}:role/${var.member_admin_role_name}"
    session_name = "spotto-onboarding"
  }
}

provider "aws" {
  alias   = "workload"
  region  = "us-east-1"
  profile = var.aws_profile

  assume_role {
    role_arn     = "arn:aws:iam::${var.workload_account_id}:role/${var.member_admin_role_name}"
    session_name = "spotto-onboarding"
  }
}
