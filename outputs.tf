output "app_context_parameter_name" {
  description = "Name of the SSM parameter storing app context"
  value       = aws_ssm_parameter.app_context.name
}

output "app_context_parameter_arn" {
  description = "ARN of the SSM parameter storing app context"
  value       = aws_ssm_parameter.app_context.arn
}

output "okta_credentials_parameter_arn" {
  description = "ARN of the SSM parameter storing Okta credentials"
  value       = aws_ssm_parameter.okta_credentials.arn
}

output "okta_credentials_parameter_name" {
  description = "Name of the SSM parameter storing Okta credentials"
  value       = aws_ssm_parameter.okta_credentials.name
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

# DynamoDB table outputs
output "conversations_table_name" {
  description = "Name of the conversations DynamoDB table"
  value       = module.dynamodb_tables.conversations_table_name
}

output "conversations_table_arn" {
  description = "ARN of the conversations DynamoDB table"
  value       = module.dynamodb_tables.conversations_table_arn
}

output "access_requests_table_name" {
  description = "Name of the access requests DynamoDB table"
  value       = module.dynamodb_tables.access_requests_table_name
}

output "access_requests_table_arn" {
  description = "ARN of the access requests DynamoDB table"
  value       = module.dynamodb_tables.access_requests_table_arn
}

output "approval_messages_table_name" {
  description = "Name of the approval messages DynamoDB table"
  value       = module.dynamodb_tables.approval_messages_table_name
}

output "approval_messages_table_arn" {
  description = "ARN of the approval messages DynamoDB table"
  value       = module.dynamodb_tables.approval_messages_table_arn
}

# API Gateway outputs
output "api_gateway_url" {
  description = "Base URL of the API Gateway (use this for Slack webhook configuration)"
  value       = "${aws_api_gateway_stage.prod.invoke_url}/slack/events"
}

output "api_gateway_id" {
  description = "ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.hagrid_api.id
}

# Event Handler Lambda outputs
output "event_handler_function_name" {
  description = "Name of the Event Handler Lambda function"
  value       = module.event_handler_lambda.function_name
}

output "event_handler_function_arn" {
  description = "ARN of the Event Handler Lambda function"
  value       = module.event_handler_lambda.function_arn
}
