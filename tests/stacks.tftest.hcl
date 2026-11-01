# Stack wiring with a mocked AWS provider. Nothing contacts AWS.

mock_provider "aws" {
  mock_resource "aws_cloudformation_stack" {
    defaults = {
      outputs = {
        RoleArn           = "arn:aws:iam::111122223333:role/SpottoReadOnlyRole"
        BillingBucketName = "spotto-billing-111122223333-prod-us"
        ExportArn         = "arn:aws:bcm-data-exports:us-east-1:111122223333:export/spotto-cur2-0f8fad5b"
      }
    }
  }
}

variables {
  deployment             = "prod-us"
  registration_topic_arn = "arn:aws:sns:us-east-1:715809501612:spotto-aws-connect-prod-us"
  external_id            = "spotto-0f8fad5b-d9cb-469f-a165-70867728950e"
  trusted_principal_arn  = "arn:aws:iam::999988887777:role/example-engine"
}

run "new_export_plan" {
  command = plan

  assert {
    condition     = aws_cloudformation_stack.connect.name == "SpottoConnect-prod-us"
    error_message = "The connect stack must be named SpottoConnect-prod-us."
  }

  assert {
    condition     = aws_cloudformation_stack.connect.template_url == "https://spotto-aws-onboarding.s3.amazonaws.com/cloudformation/v2026-10-30.1/spotto-aws-connect.template.json"
    error_message = "The connect stack must use the pinned versioned connect template."
  }

  assert {
    condition     = aws_cloudformation_stack.connect.capabilities == toset(["CAPABILITY_NAMED_IAM"])
    error_message = "The connect stack needs CAPABILITY_NAMED_IAM."
  }

  assert {
    condition     = aws_cloudformation_stack.connect.region == "us-east-1"
    error_message = "The connect stack must be created in us-east-1."
  }

  assert {
    condition = aws_cloudformation_stack.connect.parameters == tomap({
      ExternalId           = "spotto-0f8fad5b-d9cb-469f-a165-70867728950e"
      TrustedPrincipalArn  = "arn:aws:iam::999988887777:role/example-engine"
      CostData             = "CreateExport"
      Deployment           = "prod-us"
      RegistrationTopicArn = "arn:aws:sns:us-east-1:715809501612:spotto-aws-connect-prod-us"
      BillingExportName    = "spotto-cur2-prod-us"
      RoleName             = "SpottoReadOnlyRole"
      RepairToken          = ""
    })
    error_message = "Unexpected connect stack parameters."
  }

  assert {
    condition     = length(aws_cloudformation_stack.billing_access) == 0 && length(aws_cloudformation_stack.member_accounts) == 0
    error_message = "Only the connect stack is expected by default."
  }
}

run "new_export_outputs" {
  assert {
    condition     = output.role_arn == "arn:aws:iam::111122223333:role/SpottoReadOnlyRole"
    error_message = "role_arn must come from the stack output."
  }

  assert {
    condition     = output.billing_bucket_name == "spotto-billing-111122223333-prod-us"
    error_message = "billing_bucket_name must come from the stack output."
  }

  assert {
    condition     = output.export_arn == "arn:aws:bcm-data-exports:us-east-1:111122223333:export/spotto-cur2-0f8fad5b"
    error_message = "export_arn must come from the stack output."
  }

  assert {
    condition     = output.connect_stack_id != null && output.billing_access_stack_id == null && output.member_accounts_stack_id == null
    error_message = "Only the connect stack ID is expected."
  }
}

run "existing_export" {
  variables {
    existing_export = {
      export_name = "finance-cur2"
      bucket_name = "example-billing-exports"
      base_prefix = "exports/cur2"
      kms_key_arn = "arn:aws:kms:us-east-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    }
  }

  override_resource {
    target = aws_cloudformation_stack.connect
    values = {
      outputs = { RoleArn = "arn:aws:iam::111122223333:role/SpottoReadOnlyRole", BillingBucketName = "", ExportArn = "" }
    }
  }

  assert {
    condition     = aws_cloudformation_stack.connect.parameters["CostData"] == "None"
    error_message = "An existing export must deploy the connect stack with CostData=None."
  }

  assert {
    condition     = aws_cloudformation_stack.billing_access[0].name == "SpottoBillingAccess-prod-us"
    error_message = "The billing access stack must be named SpottoBillingAccess-prod-us."
  }

  assert {
    condition     = aws_cloudformation_stack.billing_access[0].region == "us-east-1"
    error_message = "The billing access stack must be created in us-east-1."
  }

  assert {
    condition     = aws_cloudformation_stack.billing_access[0].template_url == "https://spotto-aws-onboarding.s3.amazonaws.com/cloudformation/v2026-10-30.1/spotto-aws-billing-access.template.json"
    error_message = "The billing access stack must use the pinned versioned billing access template."
  }

  assert {
    condition = aws_cloudformation_stack.billing_access[0].parameters == tomap({
      RoleName    = "SpottoReadOnlyRole"
      ExportName  = "finance-cur2"
      BucketName  = "example-billing-exports"
      BasePrefix  = "exports/cur2"
      KmsKeyArn   = "arn:aws:kms:us-east-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"
      RepairToken = ""
    })
    error_message = "Unexpected billing access stack parameters."
  }

  assert {
    condition     = output.billing_bucket_name == "example-billing-exports" && output.export_arn == null
    error_message = "The existing export's bucket is expected, and no export is created."
  }

  assert {
    condition     = output.billing_access_stack_id != null && output.member_accounts_stack_id == null
    error_message = "The billing access stack ID is expected."
  }
}

run "existing_export_defaults" {
  command = plan

  variables {
    existing_export = { export_name = "finance-cur2", bucket_name = "example-billing-exports" }
  }

  assert {
    condition     = aws_cloudformation_stack.billing_access[0].parameters["BasePrefix"] == "" && aws_cloudformation_stack.billing_access[0].parameters["KmsKeyArn"] == ""
    error_message = "base_prefix and kms_key_arn default to empty."
  }
}

run "repair_token" {
  command = plan

  variables {
    connect_member_accounts = true
    organizational_unit_ids = ["r-ab12"]
    repair_token            = "1792650000"
  }

  assert {
    condition     = aws_cloudformation_stack.connect.parameters["RepairToken"] == "1792650000"
    error_message = "repair_token must reach the connect stack as RepairToken."
  }

  assert {
    condition     = aws_cloudformation_stack.member_accounts[0].parameters["RepairToken"] == "1792650000"
    error_message = "repair_token must reach the members stack so the StackSet re-applies member roles."
  }
}

run "organization_members" {
  variables {
    connect_member_accounts = true
    organizational_unit_ids = ["r-ab12", "ou-ab12-abcd1234"]
    role_name               = "ExampleReadOnlyRole"
    template_base_url       = "https://example-templates.s3.amazonaws.com/v2/"
  }

  assert {
    condition     = aws_cloudformation_stack.member_accounts[0].name == "SpottoMemberAccounts-prod-us"
    error_message = "The members stack must be named SpottoMemberAccounts-prod-us."
  }

  assert {
    condition     = aws_cloudformation_stack.member_accounts[0].template_url == "https://example-templates.s3.amazonaws.com/v2/spotto-aws-members.template.json"
    error_message = "template_base_url must be used for the members template."
  }

  assert {
    condition     = aws_cloudformation_stack.connect.template_url == "https://example-templates.s3.amazonaws.com/v2/spotto-aws-connect.template.json"
    error_message = "template_base_url must be used for the connect template."
  }

  assert {
    condition     = aws_cloudformation_stack.member_accounts[0].capabilities == toset(["CAPABILITY_NAMED_IAM"])
    error_message = "The members stack needs CAPABILITY_NAMED_IAM."
  }

  assert {
    condition     = aws_cloudformation_stack.member_accounts[0].region == "us-east-1"
    error_message = "The members stack must be created in us-east-1."
  }

  assert {
    condition = aws_cloudformation_stack.member_accounts[0].parameters == tomap({
      ExternalId            = "spotto-0f8fad5b-d9cb-469f-a165-70867728950e"
      TrustedPrincipalArn   = "arn:aws:iam::999988887777:role/example-engine"
      OrganizationalUnitIds = "r-ab12,ou-ab12-abcd1234"
      RoleName              = "ExampleReadOnlyRole"
      RepairToken           = ""
    })
    error_message = "Unexpected members stack parameters."
  }

  assert {
    condition     = aws_cloudformation_stack.connect.parameters["RoleName"] == "ExampleReadOnlyRole"
    error_message = "role_name must reach the connect stack."
  }

  assert {
    condition     = output.member_accounts_stack_id != null && output.billing_access_stack_id == null
    error_message = "The members stack ID is expected."
  }
}

run "eu_registration_and_storage_with_global_definition" {
  command = plan
  variables {
    deployment             = "prod-eu"
    registration_topic_arn = "arn:aws:sns:eu-north-1:715809501612:spotto-aws-connect-prod-eu"
  }
  assert {
    condition     = aws_cloudformation_stack.connect.region == "eu-north-1" && aws_cloudformation_stack.connect.parameters["Deployment"] == "prod-eu"
    error_message = "EU access and storage must be deployed to Stockholm."
  }
  assert {
    condition     = aws_cloudformation_stack.billing_export[0].region == "us-east-1" && aws_cloudformation_stack.billing_export[0].parameters["BucketRegion"] == "eu-north-1"
    error_message = "The AWS-global definition must deliver to the EU bucket."
  }
}
