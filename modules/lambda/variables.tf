variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "handler" {
  description = "Lambda function handler (e.g., index.lambda_handler)"
  type        = string
  default     = "index.lambda_handler"
}

variable "runtime" {
  description = "Lambda runtime (e.g., python3.12)"
  type        = string
  default     = "python3.12"
}

variable "memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 10
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "iam_policy_statements" {
  description = "List of IAM policy statements for custom Lambda permissions"
  type        = list(any)
  default     = []
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
}
