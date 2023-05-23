variable "backup_schedule" {
  type        = string
  default     = "cron(00 19 * * ? *)"
  description = "The scheduling expression. (e.g. cron(0 20 * * ? *) or rate(5 minutes))"
}

variable "cleanup_schedule" {
  type        = string
  default     = "cron(05 19 * * ? *)"
  description = "The scheduling expression. (e.g. cron(0 20 * * ? *) or rate(5 minutes))"
}

variable "reboot" {
  description = "Define if the instances should be rebooted during the backup process"
  type        = bool
  default     = false
}

variable "ami_owner" {
  type        = string
  default     = ""
  description = "AWS Account ID which is used as a filter for AMI list (e.g. `123456789012`)"
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region where module should operate (e.g. `us-east-1`)"
}

variable "retention_days" {
  type        = number
  default     = 14
  description = "Is the number of days you want to keep the backups for (e.g. `14`)"
}

variable "instance_id" {
  type        = string
  description = "AWS Instance ID which is used for creating the AMI image (e.g. `id-123456789012`)"
}

variable "block_device_mappings" {
  type        = list(string)
  description = "List of block device mappings to be included/excluded from created AMIs. With default value of [], AMIs will include all attached EBS volumes"
  default     = []
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}
