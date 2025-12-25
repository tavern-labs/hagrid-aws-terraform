output "app_context_parameter_name" {
  description = "Name of the SSM parameter storing app context"
  value       = aws_ssm_parameter.app_context.name
}

output "app_context_parameter_arn" {
  description = "ARN of the SSM parameter storing app context"
  value       = aws_ssm_parameter.app_context.arn
}

output "okta_secret_arn" {
  description = "ARN of the Secrets Manager secret storing Okta credentials"
  value       = aws_secretsmanager_secret.okta_credentials.arn
}

output "okta_secret_name" {
  description = "Name of the Secrets Manager secret storing Okta credentials"
  value       = aws_secretsmanager_secret.okta_credentials.name
}

output "lambda_function_name" {
  description = "Name of the Okta app group updater Lambda function"
  value       = module.okta_app_group_lambda.lambda_function_name
}

output "lambda_function_arn" {
  description = "ARN of the Okta app group updater Lambda function"
  value       = module.okta_app_group_lambda.lambda_function_arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.okta_app_group_lambda.lambda_role_arn
}
