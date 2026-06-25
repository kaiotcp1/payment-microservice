terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Application = var.app_name
      Environment = var.environment
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
      Stack       = "bootstrap"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  github_oidc_provider_url = "https://token.actions.githubusercontent.com"

  state_bucket_name = coalesce(
    var.state_bucket_name,
    "${var.app_name}-${var.environment}-${data.aws_caller_identity.current.account_id}-${var.aws_region}-tfstate"
  )

  lock_table_name = coalesce(
    var.lock_table_name,
    "${var.app_name}-${var.environment}-terraform-locks"
  )

  github_actions_role_name = coalesce(
    var.github_actions_role_name,
    "${var.app_name}-${var.environment}-github-actions-deploy"
  )

  github_oidc_subjects = length(var.github_oidc_subjects) > 0 ? var.github_oidc_subjects : [
    "repo:${var.github_owner}/${var.github_repository}:*",
  ]

  github_oidc_provider_arn = var.github_oidc_provider_arn != null ? var.github_oidc_provider_arn : aws_iam_openid_connect_provider.github_actions[0].arn
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = local.state_bucket_name

  tags = {
    Name        = local.state_bucket_name
    Description = "Terraform remote state bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  policy = data.aws_iam_policy_document.terraform_state_bucket.json
}

data "aws_iam_policy_document" "terraform_state_bucket" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.terraform_state.arn,
      "${aws_s3_bucket.terraform_state.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  count = var.create_lock_table ? 1 : 0

  name         = local.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = local.lock_table_name
    Description = "Terraform state lock table"
  }
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  count = var.github_oidc_provider_arn == null ? 1 : 0

  url = local.github_oidc_provider_url

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = var.github_oidc_thumbprints
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.github_oidc_subjects
    }
  }
}

resource "aws_iam_role" "github_actions_deploy" {
  name                 = local.github_actions_role_name
  assume_role_policy   = data.aws_iam_policy_document.github_actions_assume_role.json
  max_session_duration = 3600
  description          = "Role assumed by GitHub Actions to deploy ${var.app_name}"

  tags = {
    Name        = local.github_actions_role_name
    Description = "GitHub Actions deployment role"
  }
}

resource "aws_iam_role_policy_attachment" "administrator" {
  count = var.attach_administrator_policy ? 1 : 0

  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = toset(var.additional_policy_arns)

  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = each.value
}
