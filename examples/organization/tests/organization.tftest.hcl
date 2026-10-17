# End-to-end wiring with mocked AWS providers: per-account roles, then the portal handoff.

mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111122223333", arn = "arn:aws:sts::111122223333:assumed-role/Administrator/terraform", user_id = "AROAEXAMPLE:terraform" }
  }
  mock_data "aws_partition" {
    defaults = { partition = "aws", dns_suffix = "amazonaws.com", reverse_dns_prefix = "com.amazonaws" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::111122223333:role/SpottoReadOnlyRole", unique_id = "AROAEXAMPLEMANAGEMENT" }
  }
}

mock_provider "aws" {
  alias = "billing_storage"
  mock_data "aws_caller_identity" {
    defaults = { account_id = "000011112222", arn = "arn:aws:sts::000011112222:assumed-role/OrganizationAccountAccessRole/spotto-onboarding", user_id = "AROAEXAMPLE:spotto-onboarding" }
  }
  mock_data "aws_partition" {
    defaults = { partition = "aws", dns_suffix = "amazonaws.com", reverse_dns_prefix = "com.amazonaws" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::000011112222:role/SpottoReadOnlyRole", unique_id = "AROAEXAMPLESTORAGE01" }
  }
}

mock_provider "aws" {
  alias = "workload"
  mock_data "aws_caller_identity" {
    defaults = { account_id = "444455556666", arn = "arn:aws:sts::444455556666:assumed-role/OrganizationAccountAccessRole/spotto-onboarding", user_id = "AROAEXAMPLE:spotto-onboarding" }
  }
  mock_data "aws_partition" {
    defaults = { partition = "aws", dns_suffix = "amazonaws.com", reverse_dns_prefix = "com.amazonaws" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::444455556666:role/SpottoReadOnlyRole", unique_id = "AROAEXAMPLEWORKLOAD1" }
  }
}

variables {
  setup_package_path         = "../../tests/fixtures/spotto-aws-setup.json"
  management_account_id      = "111122223333"
  billing_storage_account_id = "000011112222"
  workload_account_id        = "444455556666"
}

run "current_api_organization_applies_roles_and_round_trips_handoff" {
  command = apply

  variables {
    setup_package_path = "../../tests/fixtures/spotto-aws-setup-current.json"
  }

  assert {
    condition = (
      length(module.spotto_management.managed_policy_arns) == 0 &&
      length(module.spotto_billing_storage.managed_policy_arns) == 0 &&
      length(module.spotto_workload.managed_policy_arns) == 0
    )
    error_message = "No account attaches managed policies for the current API package."
  }

  assert {
    condition = jsondecode(output.aws_manual_onboarding_json) == {
      kind          = "spotto.aws.manual-onboarding"
      schemaVersion = 1
      companyId     = "company-example"
      configuration = jsondecode(file(var.setup_package_path)).configuration
      results = [
        { accountId = "111122223333", roleArn = "arn:aws:iam::111122223333:role/SpottoReadOnlyRole", status = "configured" },
        { accountId = "000011112222", roleArn = "arn:aws:iam::000011112222:role/SpottoReadOnlyRole", status = "configured" },
        { accountId = "444455556666", roleArn = "arn:aws:iam::444455556666:role/SpottoReadOnlyRole", status = "configured" },
      ]
    }
    error_message = "The current API package produces the exact V1 handoff with unchanged configuration and every role result."
  }
}

run "organization_apply_produces_portal_handoff" {
  command = apply

  assert {
    condition = (
      module.spotto_management.inline_policy_names == tolist(["SpottoBillingExportRead", "SpottoCommitmentsPlanning", "SpottoGuardrails"]) &&
      module.spotto_billing_storage.inline_policy_names == tolist(["SpottoBillingExportRead", "SpottoGuardrails"]) &&
      module.spotto_workload.inline_policy_names == tolist(["SpottoGuardrails"])
    )
    error_message = "Each account provider receives only its own Spotto policies."
  }

  assert {
    condition     = [for result in jsondecode(output.aws_manual_onboarding_json).results : "${result.accountId}|${result.status}"] == ["111122223333|configured", "000011112222|configured", "444455556666|configured"]
    error_message = "The handoff reports every package account as configured."
  }

  assert {
    condition     = jsondecode(output.aws_manual_onboarding_json).configuration == jsondecode(file(var.setup_package_path)).configuration
    error_message = "The handoff carries the unchanged package configuration."
  }
}
