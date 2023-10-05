terraform {
  required_version = ">= 1.5"
  backend "s3" {
    bucket         = "forge-terraform-state-sand"
    key            = "modules/gitlab-runners/eks"
    region         = "us-east-1"
    dynamodb_table = "forge-lock-table"
    encrypt        = true
  }
}

module "new_vpc_eks_runner" {
  source = "../../modules/eks"

  enable_schedules = true

  gitlab_runner_token = var.gitlab_runner_token
  project_name        = var.project_name
  vpc_cidr_block      = var.vpc_cidr_block
  tags                = var.tags
  environment         = "DEMO"
  capacity_type       = "SPOT"
  scale_down_desired  = 0
  scale_down_minimum  = 0
  scale_down_maximum  = 1
  scale_up_desired    = 1
  scale_up_maximum    = 3
  scale_up_minimum    = 1
  concurrency         = 10

  ecr_region = "us-east-1"
  ecr_uri    = "177807608173.dkr.ecr.us-east-1.amazonaws.com/abcefgh"



  additional_policies = {
    "additional_policy" = "arn:aws:iam::aws:policy/job-function/SystemAdministrator"
  }
}

module "existing_vpc_eks_runner" {
  source = "../../modules/eks"

  enable_schedules = true

  gitlab_runner_token = var.gitlab_runner_token
  project_name        = var.project_name_2
  tags                = var.tags
  private_subnets     = module.new_vpc_eks_runner.private_subnets
  environment         = "DEMO"
  capacity_type       = "SPOT"
  scale_down_desired  = 0
  scale_down_minimum  = 0
  scale_down_maximum  = 1
  scale_up_desired    = 1
  scale_up_maximum    = 3
  scale_up_minimum    = 1
  concurrency         = 10

  ecr_region = "us-east-1"
  ecr_uri    = "177807608173.dkr.ecr.us-east-1.amazonaws.com/abcefgh"

  additional_policies = {
    "additional_policy" = "arn:aws:iam::aws:policy/job-function/SystemAdministrator"
  }
}