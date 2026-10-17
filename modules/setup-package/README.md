# setup-package

Internal module used by `account-role` and `handoff`. It parses and validates the
V1 AWS setup package downloaded from Spotto, and has no resources.

The checks match the Bash and PowerShell scripts: package kind and version, numeric schema
versions, company binding, a credential-free configuration, exactly one role per
enabled account (1–100), standard role ARNs, role purposes backed by enabled
billing sources, one shared exact trust (Spotto principal plus company External ID),
required guardrails, billing and commitments policies present exactly when their
role purposes are selected, nonempty policy `Statement` arrays, the documented
Spotto policy names and managed policy ARNs
limited to legacy `SecurityAudit`/`ReadOnlyAccess`. Current packages have an empty
managed policy list and include discovery permissions in `SpottoGuardrails`.
