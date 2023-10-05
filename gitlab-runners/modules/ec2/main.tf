locals {
  project   = lower("${var.project_name}-${var.environment}")
  base_cidr = var.vpc_cidr_block
  azs       = slice(data.aws_availability_zones.available.names, 0, 3)
  tags      = merge(var.tags, { "t_environment" = upper(var.environment) })

  public_subnets = var.vpc_cidr_block != null ? [
    cidrsubnet(local.base_cidr, 4, 1),
    cidrsubnet(local.base_cidr, 4, 2),
  ] : []

  private_subnets = var.vpc_cidr_block != null ? [
    cidrsubnet(local.base_cidr, 4, 3),
    cidrsubnet(local.base_cidr, 4, 4),
  ] : []

  iam_role_default_policies = {
    ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  use_existing_role = var.runner_role != null ? true : false
  merged_policies   = local.use_existing_role ? {} : merge(local.iam_role_default_policies, var.additional_policies)

  use_existing_vpc = var.private_subnets != null ? (length(var.private_subnets) > 0) : false

}

data "aws_availability_zones" "available" {}

provider "aws" {
  region = var.region
  default_tags {
    tags = local.tags
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "${local.project}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/code/"
  output_path = "${path.module}/lambda/output/gitlab-runner-ami-update.zip"
}

#tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "runner_ami_update" {
  filename         = "${path.module}/lambda/output/gitlab-runner-ami-update.zip"
  function_name    = "${local.project}-lambda"
  handler          = "gitlab-runner-update.lambda_handler" # updated handler name
  memory_size      = 512
  publish          = true
  role             = aws_iam_role.lambda_execution_role.arn
  runtime          = "python3.9"
  source_code_hash = filesha256(data.archive_file.lambda.output_path)
  tags             = local.tags
}

resource "aws_lambda_permission" "runner_ami_update_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.runner_ami_update.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ami_eventbridge_rule.arn
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "lambda_policy" {
  name = "${local.project}-lambda-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:PutParameter",
          "ec2:DescribeLaunchTemplates",
          "ec2:CreateLaunchTemplateVersion",
          "ec2:ModifyLaunchTemplate",
          "autoscaling:StartInstanceRefresh",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_role_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
  depends_on = [aws_iam_policy.lambda_policy]
}

data "aws_ssm_parameter" "runner_ami_id" {
  name = var.runner_ami_id_ssm_parameter_name
}

resource "aws_iam_role" "runner_role" {
  count = local.use_existing_role ? 0 : 1
  name  = "${local.project}-runner-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "merged_policies" {
  for_each   = local.merged_policies
  role       = aws_iam_role.runner_role[0].name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "runner_instance_profile" {
  name = "${local.project}-runner-role"
  role = local.use_existing_role ? var.runner_role : aws_iam_role.runner_role[0].name
  tags = local.tags
}

resource "aws_launch_template" "gitlab_runner" {
  name                   = "${local.project}-lt"
  instance_type          = var.runner_instance_type
  tags                   = local.tags
  update_default_version = true
  vpc_security_group_ids = [aws_security_group.gitlab_runner_sg.id]
  image_id               = var.custom_runner_ami != "" ? var.custom_runner_ami : data.aws_ssm_parameter.runner_ami_id.value
  key_name               = var.key_name

  instance_market_options {
    market_type = "spot"

    spot_options {
      spot_instance_type = "one-time"
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.runner_instance_profile.name
  }

  user_data = var.user_data_file != null ? base64encode(templatefile(var.user_data_file, { user_data_variables = var.user_data_variables })) : base64encode(templatefile("${path.module}/user_data.sh", { gitlab_runner_token = var.gitlab_runner_token, ecr_region = var.ecr_region, ecr_uri = var.ecr_uri, concurrency = var.concurrency, privileged = var.privileged, docker_runner_image = var.docker_runner_image }))


  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type = "gp3"
      volume_size = var.instance_volume_size
      encrypted   = true
      kms_key_id  = var.ebs_kms_key_id
    }
  }
}

resource "aws_autoscaling_group" "runner_asg" {
  name                = "${local.project}-runner-asg"
  max_size            = var.runner_asg_max_size
  min_size            = var.runner_asg_min_size
  desired_capacity    = var.runner_asg_desired_size
  vpc_zone_identifier = local.use_existing_vpc ? var.private_subnets : module.vpc[0].private_subnets

  launch_template {
    id      = aws_launch_template.gitlab_runner.id
    version = "$Latest" # Use the latest version of the launch template
  }

  dynamic "tag" {
    for_each = local.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  tag {
    key                 = "Name"
    value               = "${local.project}-runner-asg"
    propagate_at_launch = true
  }
}

resource "aws_cloudwatch_event_rule" "ami_eventbridge_rule" {
  name                = "${local.project}-rule"
  description         = "Trigger the Lambda function when the SSM parameter is updated"
  schedule_expression = "rate(24 hours)"
  tags                = local.tags

  event_pattern = jsonencode({
    "source" : ["aws.ssm"],
    "detail-type" : ["Parameter Store Change"],
    "detail" : {
      "name" : [var.runner_ami_id_ssm_parameter_name],
      "operation" : ["Update"]
    }
  })
}

resource "aws_cloudwatch_event_target" "ami_eventbridge_rule_target" {
  rule      = aws_cloudwatch_event_rule.ami_eventbridge_rule.name
  target_id = "${local.project}-trigger"
  arn       = aws_lambda_function.runner_ami_update.arn
}

# Supporting Networking Resources 
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

data "aws_subnet" "existing" {
  count = local.use_existing_vpc ? 1 : 0
  id    = var.private_subnets[0]
}

resource "aws_security_group" "gitlab_runner_sg" {
  name_prefix = "${local.project}-"
  description = "Security group for the GitLab Runner"
  vpc_id      = local.use_existing_vpc ? data.aws_subnet.existing[0].vpc_id : module.vpc[0].vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }


  tags = merge(local.tags, { "Name" = "${local.project}-sg" })
}
