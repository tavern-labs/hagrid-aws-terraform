output "hagrid_catalog_bucket_name" {
  description = "Name of the S3 bucket storing Hagrid catalog"
  value       = aws_s3_bucket.hagrid_catalog.id
}

output "hagrid_catalog_bucket_arn" {
  description = "ARN of the S3 bucket storing Hagrid catalog"
  value       = aws_s3_bucket.hagrid_catalog.arn
}

output "okta_credentials_parameter_arn" {
  description = "ARN of the SSM parameter storing Okta credentials"
  value       = aws_ssm_parameter.okta_credentials.arn
}

output "okta_credentials_parameter_name" {
  description = "Name of the SSM parameter storing Okta credentials"
  value       = aws_ssm_parameter.okta_credentials.name
}

output "catalog_builder_function_name" {
  description = "Name of the Catalog Builder Lambda function"
  value       = module.catalog_builder_lambda.function_name
}

output "catalog_builder_function_arn" {
  description = "ARN of the Catalog Builder Lambda function"
  value       = module.catalog_builder_lambda.function_arn
}

output "catalog_builder_role_arn" {
  description = "ARN of the Catalog Builder Lambda execution role"
  value       = module.catalog_builder_lambda.role_arn
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

# Conversation Manager Lambda outputs
output "conversation_manager_function_name" {
  description = "Name of the Conversation Manager Lambda function"
  value       = module.conversation_manager_lambda.function_name
}

output "conversation_manager_function_arn" {
  description = "ARN of the Conversation Manager Lambda function"
  value       = module.conversation_manager_lambda.function_arn
}

# Approval Manager Lambda outputs
output "approval_manager_function_name" {
  description = "Name of the Approval Manager Lambda function"
  value       = module.approval_manager_lambda.function_name
}

output "approval_manager_function_arn" {
  description = "ARN of the Approval Manager Lambda function"
  value       = module.approval_manager_lambda.function_arn
}

# Okta Provisioner Lambda outputs
output "okta_provisioner_function_name" {
  description = "Name of the Okta Provisioner Lambda function"
  value       = module.okta_provisioner_lambda.function_name
}

output "okta_provisioner_function_arn" {
  description = "ARN of the Okta Provisioner Lambda function"
  value       = module.okta_provisioner_lambda.function_arn
}

# GitHub Actions OIDC outputs
output "github_lambda_deploy_role_arn" {
  description = "ARN of the GitHub Actions role for Lambda deployment (use this in GitHub repository secrets)"
  value       = aws_iam_role.github_lambda_deploy.arn
}
