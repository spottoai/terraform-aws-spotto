# Uses your normal AWS session (AWS_PROFILE, IAM Identity Center/SSO, or CloudShell).
# IAM is global; the Region only selects the STS endpoint.
provider "aws" {
  region  = "us-east-1"
  profile = var.aws_profile
}
