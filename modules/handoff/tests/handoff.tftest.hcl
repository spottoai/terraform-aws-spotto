variables {
  setup_package = file("../../tests/fixtures/spotto-aws-setup.json")
  account_results = [
    { accountId = "111122223333", roleArn = "arn:aws:iam::111122223333:role/SpottoReadOnlyRole", status = "configured" },
    { accountId = "000011112222", roleArn = "arn:aws:iam::000011112222:role/SpottoReadOnlyRole", status = "configured" },
    { accountId = "444455556666", roleArn = "arn:aws:iam::444455556666:role/SpottoReadOnlyRole", status = "configured" },
  ]
}

run "handoff_matches_portal_v1_contract" {
  command = plan

  assert {
    condition     = toset(keys(jsondecode(output.aws_manual_onboarding_json))) == toset(["kind", "schemaVersion", "companyId", "configuration", "results"])
    error_message = "The portal accepts exactly these top-level keys."
  }

  assert {
    condition = (
      jsondecode(output.aws_manual_onboarding_json).kind == "spotto.aws.manual-onboarding" &&
      jsondecode(output.aws_manual_onboarding_json).schemaVersion == 1 &&
      jsondecode(output.aws_manual_onboarding_json).companyId == "company-example"
    )
    error_message = "The handoff uses the V1 kind and the package company."
  }

  assert {
    condition     = jsondecode(output.aws_manual_onboarding_json).configuration == jsondecode(var.setup_package).configuration
    error_message = "The configuration round-trips unchanged so the portal can match it to the current draft."
  }

  assert {
    condition     = alltrue([for result in jsondecode(output.aws_manual_onboarding_json).results : toset(keys(result)) == toset(["accountId", "roleArn", "status"])])
    error_message = "Each result has exactly the keys the portal accepts."
  }

  assert {
    condition = (
      !strcontains(output.aws_manual_onboarding_json, "ExternalId") &&
      !strcontains(output.aws_manual_onboarding_json, "spotto-0f1e2d3c-4b5a-6978-8796-a5b4c3d2e1f0")
    )
    error_message = "The handoff contains no External ID."
  }

  assert {
    condition     = output.all_configured
    error_message = "All accounts report configured."
  }
}

run "missing_account_is_rejected" {
  command = plan

  variables {
    account_results = [
      { accountId = "111122223333", roleArn = "arn:aws:iam::111122223333:role/SpottoReadOnlyRole", status = "configured" },
      { accountId = "000011112222", roleArn = "arn:aws:iam::000011112222:role/SpottoReadOnlyRole", status = "configured" },
    ]
  }

  expect_failures = [output.aws_manual_onboarding_json]
}

run "duplicate_account_is_rejected" {
  command = plan

  variables {
    account_results = [
      { accountId = "111122223333", roleArn = "arn:aws:iam::111122223333:role/SpottoReadOnlyRole", status = "configured" },
      { accountId = "111122223333", roleArn = "arn:aws:iam::111122223333:role/SpottoReadOnlyRole", status = "configured" },
      { accountId = "000011112222", roleArn = "arn:aws:iam::000011112222:role/SpottoReadOnlyRole", status = "configured" },
      { accountId = "444455556666", roleArn = "arn:aws:iam::444455556666:role/SpottoReadOnlyRole", status = "configured" },
    ]
  }

  expect_failures = [output.aws_manual_onboarding_json]
}

run "unexpected_role_arn_is_rejected" {
  command = plan

  variables {
    account_results = [
      { accountId = "111122223333", roleArn = "arn:aws:iam::111122223333:role/custom/SpottoReadOnlyRole", status = "configured" },
      { accountId = "000011112222", roleArn = "arn:aws:iam::000011112222:role/SpottoReadOnlyRole", status = "configured" },
      { accountId = "444455556666", roleArn = "arn:aws:iam::444455556666:role/SpottoReadOnlyRole", status = "configured" },
    ]
  }

  expect_failures = [output.aws_manual_onboarding_json]
}

run "unknown_status_is_rejected" {
  command = plan

  variables {
    account_results = [
      { accountId = "111122223333", roleArn = "arn:aws:iam::111122223333:role/SpottoReadOnlyRole", status = "verified" },
      { accountId = "000011112222", roleArn = "arn:aws:iam::000011112222:role/SpottoReadOnlyRole", status = "configured" },
      { accountId = "444455556666", roleArn = "arn:aws:iam::444455556666:role/SpottoReadOnlyRole", status = "configured" },
    ]
  }

  expect_failures = [var.account_results]
}
