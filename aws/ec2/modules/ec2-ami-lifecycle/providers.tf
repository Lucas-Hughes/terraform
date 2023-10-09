provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = var.common_tags
  }
}