# setup-package

Internal module used by `account-role` and `handoff`. It parses and validates the
V1 AWS setup package downloaded from Spotto, and has no resources.

The checks match the PowerShell wizard's: package kind and version, numeric schema
versions, company binding, a credential-free configuration, exactly one role per
enabled account (1–100), standard role ARNs, role purposes backed by enabled
billing sources, one shared exact trust (Spotto principal plus company External ID),
required guardrails, allowlisted AWS managed policies and the documented Spotto
policy names.
