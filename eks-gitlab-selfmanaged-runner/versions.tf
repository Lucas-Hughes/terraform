terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10"
    }
  }
  backend "s3" {
    bucket         = "example-terraform-state-pearson"
    key            = "testing-infra"
    region         = "us-east-1"
    dynamodb_table = "example-lock-table"
    encrypt        = true
  }
}