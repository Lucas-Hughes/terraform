variable "gitlab_runner_token" {
  type        = string
  sensitive   = true
  description = "Value to register GitLab runner"
}

variable "project_name" {
  description = "The name of the project - all resources in the module begin with this"
  type        = string
}

variable "project_name_2" {
  description = "The name of the project - all resources in the module begin with this"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to the resources"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr_block" {
  description = "The CIDR Block to use for the module to create for the runners"
  type        = string
  default     = null
}