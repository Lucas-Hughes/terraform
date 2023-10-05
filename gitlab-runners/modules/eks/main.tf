locals {
  project         = lower("${var.project_name}-${var.environment}")
  base_cidr       = var.vpc_cidr_block
  cluster_version = var.cluster_version
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  tags            = merge(var.tags, { "t_environment" = upper(var.environment) })

  public_subnets = var.vpc_cidr_block != null ? [
    cidrsubnet(local.base_cidr, 4, 1),
    cidrsubnet(local.base_cidr, 4, 2),
  ] : []

  private_subnets = var.vpc_cidr_block != null ? [
    cidrsubnet(local.base_cidr, 4, 3),
    cidrsubnet(local.base_cidr, 4, 4),
  ] : []

  iam_role_default_policies = {
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    ssm                                = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  merged_policies = merge(local.iam_role_default_policies, var.additional_policies)

  use_existing_vpc = var.private_subnets != null ? (length(var.private_subnets) > 0) : false
}

provider "aws" {
  region = var.region
  default_tags {
    tags = local.tags
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

data "aws_availability_zones" "available" {}

# EKS Module
#tfsec:ignore:aws-eks-enable-control-plane-logging
#tfsec:ignore:aws-ec2-no-public-egress-sgr
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name                   = local.project
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = false
  enable_irsa                    = false

  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      # Specify the VPC CNI addon should be deployed before compute to ensure
      # the addon is configured before data plane compute resources are created
      before_compute = true
      most_recent    = true # To ensure access to the latest settings provided
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  vpc_id     = local.use_existing_vpc ? data.aws_subnet.existing[0].vpc_id : module.vpc[0].vpc_id
  subnet_ids = local.use_existing_vpc ? var.private_subnets : module.vpc[0].private_subnets

  eks_managed_node_groups = {

    eks-gitlab-runner = {
      name       = var.project_name
      subnet_ids = local.use_existing_vpc ? var.private_subnets : module.vpc[0].private_subnets

      min_size     = var.runner_asg_min_size
      max_size     = var.runner_asg_max_size
      desired_size = var.runner_asg_desired_size

      ami_id                     = data.aws_ami.pcm_eks_ami.id
      enable_bootstrap_user_data = true
      post_bootstrap_user_data   = templatefile("${path.module}/user_data.sh", { gitlab_runner_token = var.gitlab_runner_token, ecr_region = var.ecr_region, ecr_uri = var.ecr_uri, concurrency = var.concurrency, privileged = var.privileged, docker_runner_image = var.docker_runner_image })

      capacity_type        = var.capacity_type
      force_update_version = true
      instance_types       = var.instance_types

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "enabled"
      }

      iam_role_additional_policies = local.merged_policies

      ebs_optimized     = true
      enable_monitoring = true

      schedules = var.enable_schedules ? {
        scale-up = {
          min_size     = var.scale_up_minimum
          max_size     = var.scale_up_maximum
          desired_size = var.scale_up_desired
          timezone     = "Etc/GMT+0"
          recurrence   = var.scale_up_cron
        },
        scale-down = {
          min_size     = var.scale_down_minimum
          max_size     = var.scale_down_maximum
          desired_size = var.scale_down_desired
          timezone     = "Etc/GMT+0"
          recurrence   = var.scale_down_cron
        }
      } : {}

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.runner_volume_size
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 150
            encrypted             = true
            kms_key_id            = var.runner_kms_key != "" ? var.runner_kms_key : null
            delete_on_termination = true
          }
        }
      }
    }
  }

  tags = local.tags
}

# Supporting Resources 
data "aws_subnet" "existing" {
  count = local.use_existing_vpc ? 1 : 0
  id    = var.private_subnets[0]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  count   = local.use_existing_vpc ? 0 : 1

  name = local.project
  cidr = local.base_cidr

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.tags

  flow_log_destination_type = "s3"
  flow_log_destination_arn  = "arn:aws:s3:::central-vpcflowlogs-us-east-1-424004645979"
}

data "aws_ami" "pcm_eks_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["pcm-amzn-eks-node-${local.cluster_version}-*"]
  }
}