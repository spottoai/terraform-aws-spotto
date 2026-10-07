module "package" {
  source = "../setup-package"

  setup_package = var.setup_package
}

locals {
  result_account_ids = [for result in var.account_results : result.accountId]

  # Same V1 handoff the PowerShell wizard writes; the portal reads it without saving or
  # treating it as proof of effective Spotto access.
  handoff = {
    kind          = "spotto.aws.manual-onboarding"
    schemaVersion = 1
    companyId     = module.package.company_id
    configuration = module.package.configuration
    results       = var.account_results
  }
  handoff_json = jsonencode(local.handoff)

  # Exact UTF-8 size: base64 output is 4 characters per 3 bytes, minus padding.
  handoff_base64 = base64encode(local.handoff_json)
  handoff_bytes = (
    length(local.handoff_base64) / 4 * 3 -
    length(replace(substr(local.handoff_base64, length(local.handoff_base64) - 2, 2), "/[^=]/", ""))
  )
}
