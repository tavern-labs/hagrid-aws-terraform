locals {
  common_tags = {
    Project = var.project_name
  }
}

# SSM Parameter to store Okta catalog for the AI bot
resource "aws_ssm_parameter" "okta_catalog" {
  name        = "/${var.project_name}/okta-catalog"
  description = "Context information about Okta apps and groups for AI bot"
  type        = "SecureString"
  value       = "Placeholder - will be updated by catalog-builder Lambda"

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.project_name}-okta-catalog"
      Description = "Auto-updated by catalog-builder Lambda"
    }
  )

  lifecycle {
    ignore_changes = [value]
  }
}

# SSM Parameter to store Okta API credentials
resource "aws_ssm_parameter" "okta_credentials" {
  name        = "/${var.project_name}/okta-credentials"
  description = "Okta API credentials for app group context updater"
  type        = "SecureString"
  value = jsonencode({
    domain    = "your-domain.okta.com"
    api_token = "your-api-token-here"
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-okta-credentials"
    }
  )

  lifecycle {
    ignore_changes = [value]
  }
}

# SSM Parameter to store Slack signing secret
resource "aws_ssm_parameter" "slack_signing_secret" {
  name        = "/${var.project_name}/slack-signing-secret"
  description = "Slack signing secret for webhook request verification"
  type        = "SecureString"
  value       = "placeholder"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-slack-signing-secret"
    }
  )

  lifecycle {
    ignore_changes = [value]
  }
}

# SSM Parameter to store Slack bot token
resource "aws_ssm_parameter" "slack_bot_token" {
  name        = "/${var.project_name}/slack-bot-token"
  description = "Slack bot token for API authentication"
  type        = "SecureString"
  value       = "placeholder"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-slack-bot-token"
    }
  )

  lifecycle {
    ignore_changes = [value]
  }
}

# SSM Parameter to store Gemini API key
resource "aws_ssm_parameter" "gemini_api_key" {
  name        = "/${var.project_name}/gemini-api-key"
  description = "Google Gemini API key for AI processing"
  type        = "SecureString"
  value       = "placeholder"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-gemini-api-key"
    }
  )

  lifecycle {
    ignore_changes = [value]
  }
}

# SSM Parameter to store system prompt
resource "aws_ssm_parameter" "system_prompt" {
  name        = "/${var.project_name}/system-prompt"
  description = "System prompt for AI bot behavior and instructions"
  type        = "String"
  value       = "Placeholder - configure system prompt for AI behavior"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-system-prompt"
    }
  )

  lifecycle {
    ignore_changes = [value]
  }
}

# Catalog Builder Lambda - builds context from Okta apps and groups
module "catalog_builder_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-catalog-builder"
  handler       = "index.lambda_handler"
  runtime       = "python3.12"
  memory_size   = 512
  timeout       = 300
  aws_region    = var.aws_region
  role_arn      = aws_iam_role.catalog_builder_lambda_role.arn

  environment_variables = {
    SSM_PARAMETER_NAME        = aws_ssm_parameter.okta_catalog.name
    OKTA_CREDENTIALS_SSM_NAME = aws_ssm_parameter.okta_credentials.name
    LOG_LEVEL                 = "INFO"
  }
}

# DynamoDB tables for Hagrid Slack bot
module "dynamodb_tables" {
  source = "./modules/dynamodb_tables"

  project_name = var.project_name
}

# Event Handler Lambda - Slack webhook receiver that validates and routes incoming events
module "event_handler_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-event-handler"
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  memory_size   = 256
  timeout       = 30
  aws_region    = var.aws_region
  role_arn      = aws_iam_role.event_handler_lambda_role.arn

  environment_variables = {
    CONVERSATIONS_TABLE        = module.dynamodb_tables.conversations_table_name
    ACCESS_REQUESTS_TABLE      = module.dynamodb_tables.access_requests_table_name
    APPROVAL_MESSAGES_TABLE    = module.dynamodb_tables.approval_messages_table_name
    SSM_PARAMETER_NAME         = aws_ssm_parameter.app_context.name
    OKTA_CREDENTIALS_SSM_NAME  = aws_ssm_parameter.okta_credentials.name
    SLACK_SIGNING_SECRET_SSM   = aws_ssm_parameter.slack_signing_secret.name
    LOG_LEVEL                  = "INFO"
  }
}

# Conversation Manager Lambda - AI/NLP processing engine for intent detection and conversation flow
module "conversation_manager_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-conversation-manager"
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  memory_size   = 512
  timeout       = 60
  aws_region    = var.aws_region
  role_arn      = aws_iam_role.conversation_manager_lambda_role.arn

  environment_variables = {
    CONVERSATIONS_TABLE        = module.dynamodb_tables.conversations_table_name
    ACCESS_REQUESTS_TABLE      = module.dynamodb_tables.access_requests_table_name
    APPROVAL_MESSAGES_TABLE    = module.dynamodb_tables.approval_messages_table_name
    SSM_PARAMETER_NAME         = aws_ssm_parameter.app_context.name
    LOG_LEVEL                  = "INFO"
  }
}

# Approval Manager Lambda - Sends approval DMs to designated approvers and handles button responses
module "approval_manager_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-approval-manager"
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  memory_size   = 256
  timeout       = 30
  aws_region    = var.aws_region
  role_arn      = aws_iam_role.approval_manager_lambda_role.arn

  environment_variables = {
    CONVERSATIONS_TABLE        = module.dynamodb_tables.conversations_table_name
    ACCESS_REQUESTS_TABLE      = module.dynamodb_tables.access_requests_table_name
    APPROVAL_MESSAGES_TABLE    = module.dynamodb_tables.approval_messages_table_name
    OKTA_PROVISIONER_FUNCTION  = "${var.project_name}-okta-provisioner"
    LOG_LEVEL                  = "INFO"
  }
}

# Okta Provisioner Lambda - Adds users to Okta groups upon approval
module "okta_provisioner_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-okta-provisioner"
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  memory_size   = 256
  timeout       = 30
  aws_region    = var.aws_region
  role_arn      = aws_iam_role.okta_provisioner_lambda_role.arn

  environment_variables = {
    OKTA_CREDENTIALS_SSM_NAME = aws_ssm_parameter.okta_credentials.name
    LOG_LEVEL                 = "INFO"
  }
}

# API Gateway REST API for Slack webhook
resource "aws_api_gateway_rest_api" "hagrid_api" {
  name        = "${var.project_name}-api"
  description = "API Gateway for Hagrid Slack bot webhook events"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-api"
    }
  )
}

# API Gateway account settings for CloudWatch logging
# This is a one-time account-level setting required for stage logging
resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

# API Gateway resource: /slack
resource "aws_api_gateway_resource" "slack" {
  rest_api_id = aws_api_gateway_rest_api.hagrid_api.id
  parent_id   = aws_api_gateway_rest_api.hagrid_api.root_resource_id
  path_part   = "slack"
}

# API Gateway resource: /slack/events
resource "aws_api_gateway_resource" "events" {
  rest_api_id = aws_api_gateway_rest_api.hagrid_api.id
  parent_id   = aws_api_gateway_resource.slack.id
  path_part   = "events"
}

# API Gateway method: POST /slack/events
resource "aws_api_gateway_method" "post_events" {
  rest_api_id   = aws_api_gateway_rest_api.hagrid_api.id
  resource_id   = aws_api_gateway_resource.events.id
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway Lambda integration
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.hagrid_api.id
  resource_id             = aws_api_gateway_resource.events.id
  http_method             = aws_api_gateway_method.post_events.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.event_handler_lambda.invoke_arn
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "prod" {
  rest_api_id = aws_api_gateway_rest_api.hagrid_api.id

  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]

  # Force new deployment on every apply to pick up changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.events.id,
      aws_api_gateway_method.post_events.id,
      aws_api_gateway_integration.lambda_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway stage: prod
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.prod.id
  rest_api_id   = aws_api_gateway_rest_api.hagrid_api.id
  stage_name    = "prod"

  # Ensure account-level CloudWatch settings are configured first
  depends_on = [
    aws_api_gateway_account.main
  ]

  # Enable CloudWatch logging for debugging
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-api-prod"
    }
  )
}

# CloudWatch log group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${var.project_name}-api"
  retention_in_days = 7

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-api-logs"
    }
  )
}

# Lambda permission for API Gateway to invoke the function
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.event_handler_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.hagrid_api.execution_arn}/*/*"
}
