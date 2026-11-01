# Sign in to the organization's management account (AWS_PROFILE, IAM Identity Center/SSO, or CloudShell).
# The module creates its stacks in us-east-1 whatever Region you choose here.
provider "aws" {
  region  = "us-east-1"
  profile = var.aws_profile
}
