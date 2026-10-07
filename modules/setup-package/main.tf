# Parses and validates the portal-authored setup package. Policies, trust and the company
# External ID come from the Spotto API; this module never generates IAM permissions.
# Checks mirror Read-SpottoAwsSetupPackage in spotto-tools/onboarding/aws/Setup-SpottoAws.ps1.

locals {
  package       = jsondecode(var.setup_package)
  configuration = try(local.package.configuration, null)
  package_roles = try([for role in local.package.roles : role], [])
  company_id    = try(tostring(local.package.companyId), "")

  managed_policy_allowlist = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
    "arn:aws:iam::aws:policy/SecurityAudit",
  ]

  # Every schemaVersion, at any depth, must be the JSON number 1 (not "1" or true).
  schema_versions_valid = alltrue([
    for match in regexall("\"schemaVersion\":([^,}\\]]*)", jsonencode(local.package)) : match[0] == "1"
  ])

  package_header_valid = try(
    local.package.kind == "spotto.aws.setup" &&
    local.package.schemaVersion == 1 &&
    can(regex("^[A-Za-z0-9_-]{1,256}$", local.package.companyId)),
    false
  )

  configuration_valid = try(
    local.configuration.provider == "AWS" &&
    local.configuration.schemaVersion == 1 &&
    local.configuration.companyId == local.company_id &&
    alltrue([
      for estate in local.configuration.estates :
      estate.companyId == local.company_id &&
      (estate.enabled == true || estate.enabled == false) &&
      can([for account in estate.accounts : account]) &&
      can([for source in estate.billingSources : source]) &&
      alltrue([for account in estate.accounts : account.companyId == local.company_id && (account.enabled == true || account.enabled == false)])
    ]),
    false
  )

  # The configuration is echoed into the portal handoff, which must stay credential-free.
  configuration_credential_free = !can(regex(
    "\"(accessKeyId|secretAccessKey|sessionToken|credentials|resolvedCredentials|secret|encryptedSecret|credentialReference|accessToken|connectionString|sasToken|storageCredential|externalId)\":",
    jsonencode(local.configuration)
  ))

  # Matches the portal package builder: only enabled accounts in enabled estates receive roles,
  # and billing purposes count only when an enabled billing source assigns that account.
  enabled_accounts = try(flatten([
    for estate in local.configuration.estates : [
      for account in estate.accounts : {
        account_id = account.accountId
        role_arn   = account.roleArn
        purposes = sort([
          for purpose in account.purposes : purpose
          if !(purpose == "billing-definition" && !anytrue([for source in estate.billingSources : source.enabled == true && source.definitionRoleAccountId == account.accountId])) &&
          !(purpose == "billing-storage" && !anytrue([for source in estate.billingSources : source.enabled == true && source.storageRoleAccountId == account.accountId]))
        ])
      } if estate.enabled == true && account.enabled == true
    ]
  ]), [])

  role_account_ids    = [for role in local.package_roles : try(tostring(role.accountId), "")]
  enabled_account_ids = [for account in local.enabled_accounts : account.account_id]

  roles_cover_configuration = (
    length(local.package_roles) >= 1 &&
    length(local.package_roles) <= 100 &&
    length(distinct(local.role_account_ids)) == length(local.role_account_ids) &&
    length(distinct(local.enabled_account_ids)) == length(local.enabled_account_ids) &&
    toset(local.role_account_ids) == toset(local.enabled_account_ids)
  )

  # Every role in one package carries the same immutable company trust.
  external_id           = try(tostring(local.package_roles[0].setup.externalId), "")
  trusted_principal_arn = try(tostring(local.package_roles[0].setup.onboardingBundle.trustedPrincipalArn), "")

  role_checks = [
    for role in local.package_roles : {
      account_id = try(tostring(role.accountId), "<missing>")
      binding = try(
        can(regex("^[0-9]{12}$", role.accountId)) &&
        role.roleArn == "arn:aws:iam::${role.accountId}:role/SpottoReadOnlyRole" &&
        contains([for account in local.enabled_accounts : "${account.account_id}|${account.role_arn}"], "${role.accountId}|${role.roleArn}"),
        false
      )
      purposes = try(
        contains(role.setup.onboardingBundle.rolePurposes, "resource-discovery") &&
        sort(role.setup.onboardingBundle.rolePurposes) == one([for account in local.enabled_accounts : account.purposes if account.account_id == role.accountId]),
        false
      )
      trust = try(
        role.setup.provider == "AWS" &&
        can(regex("^spotto-[A-Za-z0-9-]{8,256}$", role.setup.externalId)) &&
        role.setup.externalId == local.external_id &&
        role.setup.onboardingBundle.schemaVersion == 1 &&
        role.setup.onboardingBundle.roleName == "SpottoReadOnlyRole" &&
        can(regex("^arn:aws:iam::[0-9]{12}:(user|role)/[A-Za-z0-9+=,.@_/-]{1,512}$", role.setup.onboardingBundle.trustedPrincipalArn)) &&
        role.setup.onboardingBundle.trustedPrincipalArn == local.trusted_principal_arn &&
        length(role.setup.onboardingBundle.trustPolicy.Statement) == 1 &&
        role.setup.onboardingBundle.trustPolicy.Statement[0].Effect == "Allow" &&
        role.setup.onboardingBundle.trustPolicy.Statement[0].Action == "sts:AssumeRole" &&
        length(keys(role.setup.onboardingBundle.trustPolicy.Statement[0].Principal)) == 1 &&
        role.setup.onboardingBundle.trustPolicy.Statement[0].Principal.AWS == local.trusted_principal_arn &&
        role.setup.onboardingBundle.trustPolicy.Statement[0].Condition.StringEquals["sts:ExternalId"] == local.external_id,
        false
      )
      policies = try(
        role.setup.onboardingBundle.guardrailPolicyName == "SpottoGuardrails" &&
        length(role.setup.onboardingBundle.guardrailPolicy.Statement) > 0 &&
        toset([for policy in role.setup.onboardingBundle.managedPolicies : policy.arn]) == toset(local.managed_policy_allowlist) &&
        (!can(role.setup.onboardingBundle.billingAccessPolicy) || try(role.setup.onboardingBundle.billingAccessPolicyName == "SpottoBillingExportRead", false)) &&
        (!can(role.setup.onboardingBundle.commitmentsAccessPolicy) || try(role.setup.onboardingBundle.commitmentsAccessPolicyName == "SpottoCommitmentsPlanning", false)),
        false
      )
    }
  ]

  # Only the three documented Spotto inline policy names are ever managed.
  roles = try({
    for role in local.package_roles : role.accountId => {
      account_id        = role.accountId
      role_arn          = role.roleArn
      role_purposes     = sort(role.setup.onboardingBundle.rolePurposes)
      trust_policy_json = jsonencode(role.setup.onboardingBundle.trustPolicy)
      inline_policies = merge(
        { SpottoGuardrails = jsonencode(role.setup.onboardingBundle.guardrailPolicy) },
        can(role.setup.onboardingBundle.billingAccessPolicy) ? { SpottoBillingExportRead = jsonencode(role.setup.onboardingBundle.billingAccessPolicy) } : {},
        can(role.setup.onboardingBundle.commitmentsAccessPolicy) ? { SpottoCommitmentsPlanning = jsonencode(role.setup.onboardingBundle.commitmentsAccessPolicy) } : {},
      )
      managed_policy_arns = sort(distinct([for policy in role.setup.onboardingBundle.managedPolicies : policy.arn]))
    }
  }, {})
}
