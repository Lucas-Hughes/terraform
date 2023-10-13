
variable "gitlab_runner_token" {
  description = "GitLab Runner Token"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "environment" {
  type        = string
  description = "Environment you're working in"
  default     = "DEV"
}

variable "project_name" {
  type        = string
  description = "Prefix of the project that will be used throughout the deployment"
  default     = ""
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR block"
  default     = null
}

variable "region" {
  type        = string
  description = "AWS Region"
  default     = "us-east-1"
}

variable "runner_instance_type" {
  type        = string
  description = "The EC2 instance type for the GitLab Runner"
  default     = "t3.medium"
}

variable "ebs_kms_key_id" {
  type        = string
  description = "KMS Key ID to encrypt EBS volumes on the GitLab Runner"
  default     = ""
}

variable "custom_runner_ami" {
  type        = string
  description = "Custom AMI to be used in the GitLab runner. If left blank, it will source the latest Amazon Linux 2 image"
  default     = ""
}

variable "key_name" {
  type        = string
  description = "Name of the SSH keypair to utilize in the runner launch template"
  default     = null
}

variable "instance_volume_size" {
  type        = number
  description = "The size of the EBS volume on the GitLab runner"
  default     = 30
}

variable "runner_asg_max_size" {
  type        = number
  description = "Max number of instances you want running in the runner ASG"
  default     = 3
}

variable "runner_asg_min_size" {
  type        = number
  description = "Minimum number of instances you want running in the runner ASG"
  default     = 1
}

variable "runner_asg_desired_size" {
  type        = number
  description = "Desired number of instances you want running in the runner ASG"
  default     = 2
}

variable "additional_policies" {
  description = "Additional IAM policies to be merged. Format is whatever_name = arn_of_policy."
  type        = map(string)
  default     = {}
}

variable "ecr_region" {
  description = "The AWS region of the ECR repository. Defaults to ''"
  type        = string
  default     = ""
}

variable "ecr_uri" {
  description = "The URI of the ECR image that you're wanting to authenticate to"
  type        = string
  default     = ""
}

variable "concurrency" {
  description = "The amount of jobs you want to run concurrently - https://docs.gitlab.com/runner/configuration/advanced-configuration.html"
  type        = number
  default     = 15
}

variable "privileged" {
  description = "Allows the docker containers to run in privileged mode. Necessary for DinD. Please note that this is insecure and should only be used if using DinD"
  type        = bool
  default     = false
}

variable "private_subnets" {
  description = "List of private subnets where the GitLab runner will be deployed."
  type        = list(string)
  default     = null
}

variable "runner_role" {
  description = "Name of the existing role to be used for deployment."
  type        = string
  default     = null
}

variable "docker_runner_image" {
  description = "The image to run jobs with inside the container"
  type        = string
  default     = "alpine:latest"
}

variable "user_data_file" {
  description = "Path to custom user data file"
  type        = string
  default     = null
}

variable "user_data_variables" {
  description = "Map of variables to be used inside of userdata"
  type        = map(any)
  default     = {}
}
