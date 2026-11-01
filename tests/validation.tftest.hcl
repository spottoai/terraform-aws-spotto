# Input checks at plan. Rejected inputs fail before anything is created.

mock_provider "aws" {}

variables {
  deployment             = "prod-us"
  registration_topic_arn = "arn:aws:sns:us-east-1:715809501612:spotto-aws-connect-prod-us"
  external_id            = "spotto-0f8fad5b-d9cb-469f-a165-70867728950e"
  trusted_principal_arn  = "arn:aws:iam::999988887777:user/example-engine"
}

run "accepts_user_principal" {
  command = plan
}

run "rejects_bad_external_id" {
  command = plan

  variables {
    external_id = "0f8fad5b-d9cb-469f-a165-70867728950e"
  }

  expect_failures = [var.external_id]
}

run "rejects_bad_trusted_principal" {
  command = plan

  variables {
    trusted_principal_arn = "arn:aws:sts::999988887777:assumed-role/example/session"
  }

  expect_failures = [var.trusted_principal_arn]
}

run "rejects_bad_cost_data" {
  command = plan

  variables {
    cost_data = "Existing"
  }

  expect_failures = [var.cost_data]
}

run "rejects_no_cost_data" {
  command = plan

  variables {
    cost_data = "None"
  }

  expect_failures = [var.cost_data]
}

run "rejects_none_with_existing_export" {
  command = plan

  variables {
    cost_data       = "None"
    existing_export = { export_name = "finance-cur2", bucket_name = "example-billing-exports" }
  }

  expect_failures = [var.cost_data]
}

run "rejects_create_export_with_existing_export" {
  command = plan

  variables {
    cost_data       = "CreateExport"
    existing_export = { export_name = "finance-cur2", bucket_name = "example-billing-exports" }
  }

  expect_failures = [var.cost_data]
}

run "rejects_bad_export_name" {
  command = plan

  variables {
    existing_export = { export_name = "finance/cur2", bucket_name = "example-billing-exports" }
  }

  expect_failures = [var.existing_export]
}

run "rejects_double_slash_in_base_prefix" {
  command = plan

  variables {
    existing_export = { export_name = "finance.cur2", bucket_name = "example-billing-exports", base_prefix = "exports//cur2" }
  }

  expect_failures = [var.existing_export]
}

run "rejects_bad_bucket_name" {
  command = plan

  variables {
    existing_export = { export_name = "finance-cur2", bucket_name = "s3://Example_Bucket" }
  }

  expect_failures = [var.existing_export]
}

run "rejects_slash_in_base_prefix" {
  command = plan

  variables {
    existing_export = { export_name = "finance-cur2", bucket_name = "example-billing-exports", base_prefix = "exports/" }
  }

  expect_failures = [var.existing_export]
}

run "rejects_kms_alias" {
  command = plan

  variables {
    existing_export = { export_name = "finance-cur2", bucket_name = "example-billing-exports", kms_key_arn = "alias/billing" }
  }

  expect_failures = [var.existing_export]
}

run "rejects_members_without_ous" {
  command = plan

  variables {
    connect_member_accounts = true
  }

  expect_failures = [var.organizational_unit_ids]
}

run "rejects_bad_ou_id" {
  command = plan

  variables {
    connect_member_accounts = true
    organizational_unit_ids = ["111122223333"]
  }

  expect_failures = [var.organizational_unit_ids]
}

run "rejects_bad_role_name" {
  command = plan

  variables {
    role_name = "Spotto Read Only"
  }

  expect_failures = [var.role_name]
}

run "rejects_non_numeric_repair_token" {
  command = plan

  variables {
    repair_token = "repair-1"
  }

  expect_failures = [var.repair_token]
}

run "rejects_long_repair_token" {
  command = plan

  variables {
    repair_token = "123456789012345"
  }

  expect_failures = [var.repair_token]
}

run "accepts_14_digit_repair_token" {
  command = plan

  variables {
    repair_token = "12345678901234"
  }
}

run "rejects_http_template_url" {
  command = plan

  variables {
    template_base_url = "http://example-templates.s3.amazonaws.com/cloudformation"
  }

  expect_failures = [var.template_base_url]
}

run "rejects_cross_environment_topic" {
  command = plan
  variables {
    registration_topic_arn = "arn:aws:sns:ap-southeast-2:715809501612:spotto-aws-connect-dev-au"
  }
  expect_failures = [var.registration_topic_arn]
}
