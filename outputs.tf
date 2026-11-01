# Only a CreateExport stack creates the bucket and export; ignore stale or absent outputs otherwise.
locals {
  connect_outputs     = aws_cloudformation_stack.connect.outputs
  created_bucket_name = local.cost_data == "CreateExport" ? lookup(local.connect_outputs, "BillingBucketName", "") : ""
  created_export_arn  = local.cost_data == "CreateExport" ? try(aws_cloudformation_stack.billing_export[0].outputs["ExportArn"], "") : ""
}

output "role_arn" {
  description = "ARN of the read-only role in this account."
  value       = lookup(local.connect_outputs, "RoleArn", null)
}

output "billing_bucket_name" {
  description = "Bucket that receives the billing export: the created bucket, the existing export's bucket, or null when there is no cost data."
  value = (
    var.existing_export != null ? var.existing_export.bucket_name :
    local.created_bucket_name != "" ? local.created_bucket_name : null
  )
}

output "export_arn" {
  description = "ARN of the spotto-cur2 export created by the stack, or null when no export was created."
  value       = local.created_export_arn != "" ? local.created_export_arn : null
}

output "connect_stack_id" {
  description = "ID of the SpottoConnect stack."
  value       = aws_cloudformation_stack.connect.id
}

output "billing_access_stack_id" {
  description = "ID of the SpottoBillingAccess stack, or null when existing_export isn't set."
  value       = one(aws_cloudformation_stack.billing_access[*].id)
}

output "member_accounts_stack_id" {
  description = "ID of the SpottoMemberAccounts stack, or null when connect_member_accounts is false."
  value       = one(aws_cloudformation_stack.member_accounts[*].id)
}

output "onboarding_region" {
  description = "Region of access, registration and newly created billing storage."
  value       = local.region
}

output "billing_export_stack_id" {
  description = "Global export-definition stack, when a new export is created."
  value       = one(aws_cloudformation_stack.billing_export[*].id)
}
