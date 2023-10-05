variable "gitlab_runner_token" {
  description = "GitLab Runner Token"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
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

variable "region" {
  type        = string
  description = "AWS Region"
  default     = "us-east-1"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR block"
  default     = null
}

variable "runner_asg_max_size" {
  type        = number
  description = "Max number of instances you want running in the runner ASG"
  default     = 7
}

variable "runner_asg_min_size" {
  type        = number
  description = "Minimum number of instances you want running in the runner ASG"
  default     = 0
}

variable "runner_asg_desired_size" {
  type        = number
  description = "Desired number of instances you want running in the runner ASG. Module has this in ignore_changes. May need to recreate or use enable_schedules to change this. "
  default     = 2
}

variable "runner_volume_size" {
  type        = number
  description = "The volume size of the runner in GB"
  default     = 30
}

variable "runner_kms_key" {
  type        = string
  description = "Customer Managed Key for encrypting EBS volumes on the runner. Defaults to AWS managed key"
  default     = null
}

variable "additional_policies" {
  description = "Additional IAM policies to be merged. Format is whatever_name = arn_of_policy."
  type        = map(string)
  default     = {}
}

variable "cluster_version" {
  description = "Version of Kubernetes to use in the EKS cluster"
  type        = string
  default     = "1.27"
}

variable "enable_schedules" {
  description = "Enable or disable scheduling for EKS"
  type        = bool
  default     = false
}

variable "scale_up_cron" {
  description = "Cron expression for scaling up. Defaults to 8am EDT/7am EST Mon-Fri"
  type        = string
  default     = "0 12 * * MON-FRI"
}

variable "scale_down_cron" {
  description = "Cron expression for scaling down. Defaults to 8am EDT/7am EST Mon-Fri"
  type        = string
  default     = "0 0 * * TUE-SAT"
}

variable "scale_down_minimum" {
  description = "The minimum number of instances allowed when the asg scales down."
  type        = number
  default     = 0
}

variable "scale_up_minimum" {
  description = "The minimum number of instances allowed when the asg scales up."
  type        = number
  default     = 2
}

variable "scale_down_desired" {
  description = "The desired number of instances allowed when the asg scales down."
  type        = number
  default     = 0
}

variable "scale_up_desired" {
  description = "The desired number of instances allowed when the asg scales up."
  type        = number
  default     = 2
}

variable "scale_down_maximum" {
  description = "The maximum number of instances allowed when the asg scales down."
  type        = number
  default     = 3
}

variable "scale_up_maximum" {
  description = "The maximum number of instances allowed when the asg scales up."
  type        = number
  default     = 7
}

variable "capacity_type" {
  type        = string
  description = "Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT. Terraform will only perform drift detection if a configuration value is provided."
  default     = "SPOT"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "The capacity_type can only be 'ON_DEMAND' or 'SPOT'."
  }
}

variable "instance_types" {
  description = "List of instance types."
  type        = list(string)
  default     = ["t3.medium", "t3.large"]
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
  default     = 10
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

variable "docker_runner_image" {
  description = "The image to run jobs with inside the container"
  type        = string
  default     = "alpine:latest"
}