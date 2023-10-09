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
    "t_AppID"       = "SVC00000"
    "t_dcl"         = "3"
    "t_environment" = "DEV"
    "Owner"         = "lucas.j.hughes@outlook.com"
  }
}
