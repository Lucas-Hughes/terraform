terraform {
  required_version = ">= 1.5"
}

module "new_vpc_ec2_runner" {
  source = "../../modules/ec2"

  gitlab_runner_token = var.gitlab_runner_token
  project_name        = var.project_name
  vpc_cidr_block      = var.vpc_cidr_block
  tags                = var.tags
  environment         = "DEMO"

  concurrency = 10

  ecr_region = "us-east-1"
  ecr_uri    = "177807608173.dkr.ecr.us-east-1.amazonaws.com/abcefgh"

  additional_policies = {
    "additional_policy" = "arn:aws:iam::aws:policy/job-function/SystemAdministrator"
  }
}

module "existing_vpc_ec2_runner" {
  source = "../../modules/ec2"

  gitlab_runner_token = var.gitlab_runner_token
  project_name        = var.project_name_2
  environment         = "DEMO"
  tags                = var.tags

  private_subnets = module.new_vpc_ec2_runner.private_subnets
  runner_role     = module.new_vpc_ec2_runner.runner_role

  concurrency         = 10
  privileged          = true # do not use this unless you are sure you need it; use for DinD
  docker_runner_image = "docker:stable"

  ecr_region = "us-east-1"
  ecr_uri    = "177807608173.dkr.ecr.us-east-1.amazonaws.com/abcefgh"

  additional_policies = {
    "additional_policy" = "arn:aws:iam::aws:policy/job-function/SystemAdministrator"
  }
}