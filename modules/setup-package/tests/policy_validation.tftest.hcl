# Policy capabilities must match selected purposes, with nonempty Statement arrays.
# These tests exercise the resource-free parser and never call AWS.

run "rejects_missing_selected_billing_policy" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = jsondecode(role.accountId == "111122223333" ? jsonencode({ for key, value in role.setup.onboardingBundle : key => value if key != "billingAccessPolicy" }) : jsonencode(role.setup.onboardingBundle))
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_null_selected_billing_policy" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = jsondecode(role.accountId == "111122223333" ? jsonencode(merge(role.setup.onboardingBundle, { billingAccessPolicy = null })) : jsonencode(role.setup.onboardingBundle))
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_selected_billing_policy_without_statements" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = jsondecode(role.accountId == "111122223333" ? jsonencode(merge(role.setup.onboardingBundle, { billingAccessPolicy = { Version = "2012-10-17" } })) : jsonencode(role.setup.onboardingBundle))
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_selected_billing_policy_with_empty_statements" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = jsondecode(role.accountId == "111122223333" ? jsonencode(merge(role.setup.onboardingBundle, { billingAccessPolicy = { Statement = [] } })) : jsonencode(role.setup.onboardingBundle))
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_selected_billing_policy_with_object_statements" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = jsondecode(role.accountId == "111122223333" ? jsonencode(merge(role.setup.onboardingBundle, { billingAccessPolicy = { Statement = { Effect = "Allow" } } })) : jsonencode(role.setup.onboardingBundle))
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_selected_billing_policy_with_wrong_name" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = jsondecode(role.accountId == "111122223333" ? jsonencode(merge(role.setup.onboardingBundle, { billingAccessPolicyName = "UnexpectedPolicy" })) : jsonencode(role.setup.onboardingBundle))
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_unselected_billing_policy" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = jsondecode(role.accountId == "444455556666" ? jsonencode(merge(role.setup.onboardingBundle, { billingAccessPolicy = { Statement = [{ Effect = "Allow", Action = "*", Resource = "*" }] }, billingAccessPolicyName = "SpottoBillingExportRead" })) : jsonencode(role.setup.onboardingBundle))
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_unselected_billing_policy_even_when_null" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = jsondecode(role.accountId == "444455556666" ? jsonencode(merge(role.setup.onboardingBundle, { billingAccessPolicy = null, billingAccessPolicyName = "SpottoBillingExportRead" })) : jsonencode(role.setup.onboardingBundle))
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_missing_selected_commitments_policy" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = jsondecode(role.accountId == "111122223333" ? jsonencode({ for key, value in role.setup.onboardingBundle : key => value if key != "commitmentsAccessPolicy" }) : jsonencode(role.setup.onboardingBundle))
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_null_selected_commitments_policy" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = jsondecode(role.accountId == "111122223333" ? jsonencode(merge(role.setup.onboardingBundle, { commitmentsAccessPolicy = null })) : jsonencode(role.setup.onboardingBundle))
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_selected_commitments_policy_without_statements" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = jsondecode(role.accountId == "111122223333" ? jsonencode(merge(role.setup.onboardingBundle, { commitmentsAccessPolicy = { Version = "2012-10-17" } })) : jsonencode(role.setup.onboardingBundle))
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_selected_commitments_policy_with_empty_statements" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = jsondecode(role.accountId == "111122223333" ? jsonencode(merge(role.setup.onboardingBundle, { commitmentsAccessPolicy = { Statement = [] } })) : jsonencode(role.setup.onboardingBundle))
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_selected_commitments_policy_with_object_statements" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = jsondecode(role.accountId == "111122223333" ? jsonencode(merge(role.setup.onboardingBundle, { commitmentsAccessPolicy = { Statement = { Effect = "Allow" } } })) : jsonencode(role.setup.onboardingBundle))
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_selected_commitments_policy_with_wrong_name" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = jsondecode(role.accountId == "111122223333" ? jsonencode(merge(role.setup.onboardingBundle, { commitmentsAccessPolicyName = "UnexpectedPolicy" })) : jsonencode(role.setup.onboardingBundle))
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_unselected_commitments_policy" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = jsondecode(role.accountId == "444455556666" ? jsonencode(merge(role.setup.onboardingBundle, { commitmentsAccessPolicy = { Statement = [{ Effect = "Allow", Action = "*", Resource = "*" }] }, commitmentsAccessPolicyName = "SpottoCommitmentsPlanning" })) : jsonencode(role.setup.onboardingBundle))
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_unselected_commitments_policy_even_when_null" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = jsondecode(role.accountId == "444455556666" ? jsonencode(merge(role.setup.onboardingBundle, { commitmentsAccessPolicy = null, commitmentsAccessPolicyName = "SpottoCommitmentsPlanning" })) : jsonencode(role.setup.onboardingBundle))
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_guardrails_with_null" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = merge(role.setup.onboardingBundle, { guardrailPolicy = null })
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_guardrails_with_missing_statements" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = merge(role.setup.onboardingBundle, { guardrailPolicy = {} })
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_guardrails_with_empty_statements" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = merge(role.setup.onboardingBundle, { guardrailPolicy = { Statement = [] } })
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_guardrails_with_object_statements" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = merge(role.setup.onboardingBundle, { guardrailPolicy = { Statement = { Effect = "Deny" } } })
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_missing_selected_billing_storage_policy" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = jsondecode(role.accountId == "000011112222" ? jsonencode({ for key, value in role.setup.onboardingBundle : key => value if key != "billingAccessPolicy" }) : jsonencode(role.setup.onboardingBundle))
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_managed_policies_empty_object" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = merge(role.setup.onboardingBundle, { managedPolicies = {} })
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_managed_policies_null" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = merge(role.setup.onboardingBundle, { managedPolicies = null })
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_managed_policies_object_of_allowlisted_entries" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = merge(role.setup.onboardingBundle, { managedPolicies = { legacy = { arn = "arn:aws:iam::aws:policy/ReadOnlyAccess" } } })
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}

run "rejects_managed_policies_missing" {
  command = plan

  variables {
    setup_package = jsonencode(merge(jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")), {
      roles = [for role in jsondecode(file("../../tests/fixtures/spotto-aws-setup-current.json")).roles : merge(role, {
        setup = merge(role.setup, {
          onboardingBundle = { for key, value in role.setup.onboardingBundle : key => value if key != "managedPolicies" }
        })
      })]
    }))
  }

  expect_failures = [output.roles]
}
