variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "hagrid"
}

variable "github_org" {
  description = "GitHub organization or username for OIDC federation"
  type        = string
  default     = "tavern-labs"
}

variable "github_lambda_repo" {
  description = "GitHub repository name for Lambda code deployments"
  type        = string
  default     = "hagrid-lambdas"
}
