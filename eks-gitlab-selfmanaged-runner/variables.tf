variable "gitlab_url" {
  description = "GitLab URL"
  type        = string
  default     = "https://gitlab.com"
}

variable "gitlab_runner_token" {
  description = "GitLab Runner Token"
  type        = string
  sensitive   = true
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}