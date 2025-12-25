variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "ssm_parameter_name" {
  description = "Name of the SSM parameter to update with context data"
  type        = string
}

variable "ssm_parameter_arn" {
  description = "ARN of the SSM parameter to update with context data"
  type        = string
}

variable "okta_credentials_ssm_arn" {
  description = "ARN of the SSM parameter containing Okta credentials"
  type        = string
}

variable "okta_credentials_ssm_name" {
  description = "Name of the SSM parameter containing Okta credentials"
  type        = string
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 300
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512
}
