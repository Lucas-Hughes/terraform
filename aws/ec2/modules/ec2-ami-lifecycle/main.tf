locals {
  t_environment = var.common_tags["t_environment"]
  instance_name = format("%s-%s", local.t_environment, var.instance_id)
  backup_name   = format("%s-backup-%s", local.t_environment, var.instance_id)
  cleanup_name  = format("%s-cleanup-%s", local.t_environment, var.instance_id)
}

data "aws_iam_policy_document" "default" {
  statement {
    sid = ""

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

data "aws_iam_policy_document" "ami_backup" {
  statement {
    actions = [
      "logs:*",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }

  statement {
    actions = [
      "ec2:DescribeInstances",
      "ec2:CreateImage",
      "ec2:DescribeImages",
      "ec2:DeregisterImage",
      "ec2:DescribeSnapshots",
      "ec2:DeleteSnapshot",
      "ec2:CreateTags",
    ]

    resources = [
      "*",
    ]
  }
}

data "archive_file" "ami_backup" {
  type        = "zip"
  source_file = "${path.module}/ami_backup.py"
  output_path = "${path.module}/ami_backup.zip"
}

data "archive_file" "ami_cleanup" {
  type        = "zip"
  source_file = "${path.module}/ami_cleanup.py"
  output_path = "${path.module}/ami_cleanup.zip"
}

resource "aws_iam_role" "ami_backup" {
  name               = local.instance_name
  assume_role_policy = data.aws_iam_policy_document.default.json
  tags               = var.common_tags
}

resource "aws_iam_role_policy" "ami_backup" {
  name   = local.instance_name
  role   = aws_iam_role.ami_backup.id
  policy = data.aws_iam_policy_document.ami_backup.json
}

data "aws_caller_identity" "current" {}

resource "aws_lambda_function" "ami_backup" {
  filename         = data.archive_file.ami_backup.output_path
  function_name    = local.backup_name
  role             = aws_iam_role.ami_backup.arn
  handler          = "ami_backup.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.ami_backup.output_base64sha256
  tags             = var.common_tags

  environment {
    variables = merge({
      region                = var.region
      ami_owner             = data.aws_caller_identity.current.account_id
      instance_id           = var.instance_id
      retention             = var.retention_days
      label_id              = local.instance_name
      reboot                = var.reboot ? "1" : "0"
      block_device_mappings = jsonencode(var.block_device_mappings)
      tag_keys              = jsonencode(keys(var.common_tags))
    }, var.common_tags)
  }
}

resource "aws_lambda_function" "ami_cleanup" {
  filename         = data.archive_file.ami_cleanup.output_path
  function_name    = local.cleanup_name
  role             = aws_iam_role.ami_backup.arn
  description      = "Automatically remove AMIs that have expired (delete AMI)"
  timeout          = 60
  handler          = "ami_cleanup.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.ami_cleanup.output_base64sha256
  tags             = var.common_tags

  environment {
    variables = {
      region      = var.region
      ami_owner   = data.aws_caller_identity.current.account_id
      instance_id = var.instance_id
      label_id    = local.instance_name
    }
  }
}

resource "null_resource" "schedule" {
  triggers = {
    backup  = var.backup_schedule
    cleanup = var.cleanup_schedule
  }
}

resource "aws_cloudwatch_event_rule" "ami_backup" {
  name                = local.backup_name
  description         = "Schedule for AMI snapshot backups"
  schedule_expression = null_resource.schedule.triggers["backup"]
  depends_on          = [null_resource.schedule]
  tags                = var.common_tags
}

resource "aws_cloudwatch_event_rule" "ami_cleanup" {
  name                = local.cleanup_name
  description         = "Schedule for AMI snapshot cleanup"
  schedule_expression = null_resource.schedule.triggers["cleanup"]
  depends_on          = [null_resource.schedule]
  tags                = var.common_tags
}

resource "aws_cloudwatch_event_target" "ami_backup" {
  rule      = aws_cloudwatch_event_rule.ami_backup.name
  target_id = local.backup_name
  arn       = aws_lambda_function.ami_backup.arn
}

resource "aws_cloudwatch_event_target" "ami_cleanup" {
  rule      = aws_cloudwatch_event_rule.ami_cleanup.name
  target_id = local.cleanup_name
  arn       = aws_lambda_function.ami_cleanup.arn
}

resource "aws_lambda_permission" "ami_backup" {
  statement_id  = local.backup_name
  function_name = aws_lambda_function.ami_backup.function_name
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ami_backup.arn
}

resource "aws_lambda_permission" "ami_cleanup" {
  statement_id  = local.cleanup_name
  function_name = aws_lambda_function.ami_cleanup.function_name
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ami_cleanup.arn
}
