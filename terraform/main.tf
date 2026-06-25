terraform {
  required_version = ">= 1.9.0"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.8"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Application = var.app_name
      Environment = var.environment
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
