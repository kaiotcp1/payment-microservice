variable "aws_region" {
  description = "AWS region used by the bootstrap stack"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Application name used in bootstrap resource names"
  type        = string
  default     = "payment-ms"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.app_name))
    error_message = "app_name must use lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name used in bootstrap resource names"
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.environment))
    error_message = "environment must use lowercase letters, numbers, and hyphens."
  }
}

variable "cost_center" {
  description = "Cost center for governance and tagging"
  type        = string
  default     = "engineering"
}

variable "github_owner" {
  description = "GitHub user or organization that owns the repository"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository name"
  type        = string
}

variable "github_oidc_subjects" {
  description = "Allowed GitHub OIDC subject claims. Defaults to repo:<owner>/<repo>:*."
  type        = list(string)
  default     = []
}

variable "github_oidc_provider_arn" {
  description = "Existing GitHub OIDC provider ARN. Leave null to create one."
  type        = string
  default     = null
}

variable "github_oidc_thumbprints" {
  description = "Thumbprints for the GitHub Actions OIDC provider."
  type        = list(string)
  default     = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

variable "github_actions_role_name" {
  description = "Name of the IAM role assumed by GitHub Actions"
  type        = string
  default     = null
}

variable "attach_administrator_policy" {
  description = "Attach AWS managed AdministratorAccess to the GitHub Actions role"
  type        = bool
  default     = true
}

variable "additional_policy_arns" {
  description = "Additional managed policy ARNs to attach to the GitHub Actions role"
  type        = list(string)
  default     = []
}

variable "state_bucket_name" {
  description = "S3 bucket name for Terraform remote state. Leave null to generate one."
  type        = string
  default     = null
}

variable "create_lock_table" {
  description = "Create a DynamoDB table for Terraform state locking"
  type        = bool
  default     = true
}

variable "lock_table_name" {
  description = "DynamoDB lock table name. Leave null to generate one."
  type        = string
  default     = null
}

variable "default_state_key" {
  description = "Suggested Terraform state key for the application stack"
  type        = string
  default     = "payment-ms/dev/terraform.tfstate"
}
