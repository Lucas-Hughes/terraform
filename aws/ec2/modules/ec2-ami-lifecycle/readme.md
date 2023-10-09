<!-- BEGIN_TF_DOCS -->

# EC2 AMI Creation with Retention Schedule Terraform Module

This Terraform module helps in creating an Amazon Machine Image (AMI) for an existing EC2 instance, with a defined retention schedule.

## Features

- Schedule backups (creates AMI) of an EC2 instance
- Schedule cleanup of AMIs older than a specified number of days
- Optional reboot of the instance during the backup process
- Inclusion/exclusion of block device mappings

## Usage

The following variables are required:

- `backup_schedule`: The scheduling expression for backups. Defaults to "cron(00 19 * * ? *)".
- `cleanup_schedule`: The scheduling expression for cleanup. Defaults to "cron(05 19 * * ? *)".
- `reboot`: Whether the instances should be rebooted during the backup process. Defaults to `false`.
- `region`: AWS Region where the module should operate. Defaults to `us-east-1`.
- `retention_days`: Number of days to keep the backups. Defaults to `14`.
- `instance_id`: AWS Instance ID used for creating the AMI image.
- `block_device_mappings`: List of block device mappings to be included from created AMIs. With a default value of `[]`, AMIs will include all attached EBS volumes.
- `common_tags`: Common tags for all resources.

```hcl
module "ec2_ami_lifecycle" {
  source  = ""
  version = "1.0.1" # Use whatever the latest version is; needs to be specifc, can't be "latest"

  backup_schedule      = "cron(00 19 * * ? *)"
  cleanup_schedule     = "cron(05 19 * * ? *)"
  reboot               = false
  region               = "us-east-1"
  retention_days       = 14
  instance_id          = "id-123456789012"

  block_device_mappings = [
    { "DeviceName" = "/dev/sda1" },
    { "DeviceName" = "/dev/sdg" },
    { "DeviceName" = "/dev/sdf" }
  ]

  common_tags = {
    "Owner"         = "lucas.j.hughes@outlook.com"
    "environment"   = "DEV"
  }
}
```

#### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.0 |

#### Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | ~> 2.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |
| <a name="provider_null"></a> [null](#provider\_null) | ~> 3.0 |

#### Modules

No modules.

#### Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.ami_backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.ami_cleanup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.ami_backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.ami_cleanup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_iam_role.ami_backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.ami_backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_lambda_function.ami_backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.ami_cleanup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.ami_backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.ami_cleanup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [null_resource.schedule](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [archive_file.ami_backup](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.ami_cleanup](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.ami_backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

#### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags for all resources | `map(string)` | n/a | yes |
| <a name="input_instance_id"></a> [instance\_id](#input\_instance\_id) | AWS Instance ID which is used for creating the AMI image (e.g. `id-123456789012`) | `string` | n/a | yes |
| <a name="input_backup_schedule"></a> [backup\_schedule](#input\_backup\_schedule) | The scheduling expression. (e.g. cron(0 20 * * ? *) or rate(5 minutes)) | `string` | `"cron(00 19 * * ? *)"` | no |
| <a name="input_block_device_mappings"></a> [block\_device\_mappings](#input\_block\_device\_mappings) | List of block device mappings to be included/excluded from created AMIs. With default value of [], AMIs will include all attached EBS volumes | `list(object({ DeviceName = string }))` | `[]` | no |
| <a name="input_cleanup_schedule"></a> [cleanup\_schedule](#input\_cleanup\_schedule) | The scheduling expression. (e.g. cron(0 20 * * ? *) or rate(5 minutes)) | `string` | `"cron(05 19 * * ? *)"` | no |
| <a name="input_reboot"></a> [reboot](#input\_reboot) | Define if the instances should be rebooted during the backup process | `bool` | `false` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region where module should operate (e.g. `us-east-1`) | `string` | `"us-east-1"` | no |
| <a name="input_retention_days"></a> [retention\_days](#input\_retention\_days) | Is the number of days you want to keep the backups for (e.g. `14`) | `number` | `14` | no |

#### Outputs

No outputs.

<!-- END_TF_DOCS -->