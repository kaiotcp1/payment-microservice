output "github_actions_role_arn" {
  description = "Set this as the AWS_ROLE_TO_ASSUME GitHub secret"
  value       = aws_iam_role.github_actions_deploy.arn
}

output "state_bucket_name" {
  description = "Set this as the TF_STATE_BUCKET GitHub repository variable"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "state_key" {
  description = "Optional TF_STATE_KEY value for the application stack"
  value       = var.default_state_key
}

output "lock_table_name" {
  description = "Set this as TF_LOCK_TABLE if create_lock_table is true"
  value       = var.create_lock_table ? aws_dynamodb_table.terraform_locks[0].name : null
}

output "github_oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN used by the deploy role"
  value       = local.github_oidc_provider_arn
}

output "github_oidc_subjects" {
  description = "GitHub OIDC subjects allowed to assume the deploy role"
  value       = local.github_oidc_subjects
}
