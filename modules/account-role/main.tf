module "package" {
  source = "../setup-package"

  setup_package = var.setup_package
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  role = try(module.package.roles[var.account_id], null)

  inline_policies     = try(local.role.inline_policies, {})
  managed_policy_arns = try(local.role.managed_policy_arns, [])
}

resource "aws_iam_role" "spotto" {
  name                 = "SpottoReadOnlyRole"
  description          = "Spotto read-only access. Managed by Terraform from the Spotto setup package."
  assume_role_policy   = try(local.role.trust_policy_json, "{}")
  permissions_boundary = var.permissions_boundary_arn

  # SpottoManagedBy=Terraform makes Setup-SpottoAws.ps1 refuse to change this role, so
  # Terraform remains its only writer. Module tags win over caller-supplied tags.
  tags = merge(var.tags, {
    SpottoCompanyId = module.package.company_id
    SpottoManagedBy = "Terraform"
  })

  lifecycle {
    precondition {
      condition     = local.role != null
      error_message = "Account ${var.account_id} is not an enabled account in the setup package. Add it in Spotto, download a new package and plan again."
    }

    precondition {
      condition     = data.aws_caller_identity.current.account_id == var.account_id
      error_message = "The AWS provider for account ${var.account_id} authenticates to account ${data.aws_caller_identity.current.account_id}. Fix the provider profile or assume_role before applying."
    }

    precondition {
      condition     = data.aws_partition.current.partition == "aws"
      error_message = "Spotto AWS onboarding supports the commercial aws partition only."
    }
  }
}

# Separate policy resources leave unrelated customer inline and managed policies untouched.
# Removing a purpose in Spotto removes only the matching Spotto policy on the next apply.
resource "aws_iam_role_policy" "spotto" {
  for_each = local.inline_policies

  name   = each.key
  role   = aws_iam_role.spotto.id
  policy = each.value
}

# Guardrails (credential-value and S3 object denies) are in place before broad read access.
resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(local.managed_policy_arns)

  role       = aws_iam_role.spotto.name
  policy_arn = each.value

  depends_on = [aws_iam_role_policy.spotto]
}
