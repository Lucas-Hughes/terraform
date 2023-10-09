data "aws_subnet" "existing" {
  count = local.use_existing_vpc ? 1 : 0
  id    = var.private_subnets[0]
}

data "aws_availability_zones" "available" {}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/code/"
  output_path = "${path.module}/lambda/output/gitlab-runner-ami-update.zip"
}

data "aws_ami" "latest_amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}
