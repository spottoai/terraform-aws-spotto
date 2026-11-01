variable "deployment" {
  description = "Owning deployment shown in the portal. Determines regional registration and new CUR storage."
  type        = string
  validation {
    condition     = contains(["dev-au", "prod-au", "prod-us", "prod-eu"], var.deployment)
    error_message = "deployment must be dev-au, prod-au, prod-us or prod-eu, exactly as shown in the portal."
  }
}

variable "registration_topic_arn" {
  description = "Registration topic supplied by the owning API. It must match deployment exactly."
  type        = string
  validation {
    condition     = var.registration_topic_arn == "arn:aws:sns:${lookup({ dev-au = "ap-southeast-2", prod-au = "ap-southeast-2", prod-us = "us-east-1", prod-eu = "eu-north-1" }, var.deployment, "invalid")}:715809501612:spotto-aws-connect-${var.deployment}"
    error_message = "registration_topic_arn must match the deployment's regional Spotto topic. Copy both values from the portal."
  }
}

variable "external_id" {
  description = "Company External ID shown in the portal (Other Ways to Connect > Terraform). Not a secret, but it binds the role to your company."
  type        = string

  validation {
    condition     = can(regex("^spotto-[0-9a-f-]{36}$", var.external_id))
    error_message = "external_id must look like spotto-<uuid>, for example spotto-0f8fad5b-d9cb-469f-a165-70867728950e."
  }
}

variable "trusted_principal_arn" {
  description = "IAM user or role ARN shown in the portal that is allowed to assume the role."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:(user|role)/[A-Za-z0-9+=,.@_/-]+$", var.trusted_principal_arn))
    error_message = "trusted_principal_arn must be an IAM user or role ARN, for example arn:aws:iam::111122223333:role/example."
  }
}

variable "cost_data" {
  description = "CreateExport (the default) creates an S3 bucket and a CUR 2.0 export named spotto-cur2. Billing is required: to read an existing export instead, leave cost_data unset and set existing_export."
  type        = string
  default     = null

  validation {
    condition     = var.cost_data == null || var.cost_data == "CreateExport"
    error_message = "Billing is required to connect AWS. Set cost_data = \"CreateExport\" (the default), or remove cost_data and set existing_export."
  }

  validation {
    condition     = var.existing_export == null || var.cost_data == null
    error_message = "cost_data = \"CreateExport\" can't be combined with existing_export. Remove cost_data."
  }
}

variable "existing_export" {
  description = "An existing CUR 2.0 export to read instead of creating one. The bucket must be in the account Terraform deploys to. base_prefix is the S3 prefix before the export name (empty when there is none)."
  type = object({
    export_name = string
    bucket_name = string
    base_prefix = optional(string, "")
    kms_key_arn = optional(string, "")
  })
  default = null

  validation {
    condition     = var.existing_export == null || can(regex("^[A-Za-z0-9][A-Za-z0-9._-]{0,255}$", var.existing_export.export_name))
    error_message = "existing_export.export_name must start with a letter or digit and contain only letters, digits, dots, underscores or hyphens (up to 256)."
  }

  validation {
    condition     = var.existing_export == null || can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.existing_export.bucket_name))
    error_message = "existing_export.bucket_name must be an S3 bucket name (3-63 lowercase letters, digits, dots or hyphens)."
  }

  validation {
    condition     = var.existing_export == null || can(regex("^(|[A-Za-z0-9!_'()=-][A-Za-z0-9!_.'()=-]*(/[A-Za-z0-9!_'()=-][A-Za-z0-9!_.'()=-]*)*)$", var.existing_export.base_prefix))
    error_message = "existing_export.base_prefix must be empty or an S3 prefix without a leading or trailing \"/\" or empty segments."
  }

  validation {
    condition     = try(var.existing_export.kms_key_arn == "" || can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[A-Za-z0-9-]+$", var.existing_export.kms_key_arn)), true)
    error_message = "existing_export.kms_key_arn must be empty or a KMS key ARN (arn:aws:kms:<region>:<account>:key/<id>)."
  }
}

variable "connect_member_accounts" {
  description = "Deploy the role to the member accounts under organizational_unit_ids with a service-managed StackSet. Apply from the organization's management account."
  type        = bool
  default     = false
}

variable "organizational_unit_ids" {
  description = "Organization root (r-xxxx) or OU IDs (ou-xxxx-xxxxxxxx) whose accounts get the role. Required when connect_member_accounts is true."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.organizational_unit_ids : can(regex("^(r-[0-9a-z]{4,32}|ou-[0-9a-z]{4,32}-[a-z0-9]{8,32})$", id))])
    error_message = "organizational_unit_ids must contain only root IDs (r-xxxx) or OU IDs (ou-xxxx-xxxxxxxx)."
  }

  validation {
    condition     = !var.connect_member_accounts || length(var.organizational_unit_ids) > 0
    error_message = "organizational_unit_ids needs at least one root or OU ID when connect_member_accounts is true."
  }
}

variable "role_name" {
  description = "Name of the read-only role in each account. Defaults to SpottoReadOnlyRole in every deployment."
  type        = string
  default     = null

  validation {
    condition     = var.role_name == null || can(regex("^[A-Za-z0-9+=,.@_-]{1,64}$", var.role_name))
    error_message = "role_name must be 1-64 letters, digits or +=,.@_- characters."
  }
}

variable "repair_token" {
  description = "Change to a new value (the current epoch seconds) and apply to re-apply the role's trust and inline policies, for example after the role was edited by hand. Empty by default."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[0-9]{0,14}$", var.repair_token))
    error_message = "repair_token must be empty or up to 14 digits, for example the output of date +%s."
  }
}

variable "template_base_url" {
  description = "HTTPS base URL of the CloudFormation templates, ending in \"/\". Defaults to the versioned path this module release pins."
  type        = string
  default     = null

  validation {
    condition     = var.template_base_url == null || can(regex("^https://.+/$", var.template_base_url))
    error_message = "template_base_url must start with https:// and end with \"/\"."
  }
}
