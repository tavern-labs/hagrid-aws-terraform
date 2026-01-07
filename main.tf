locals {
  common_tags = {
    Project = var.project_name
  }
}

# SSM Parameter to store app context for the AI bot
resource "aws_ssm_parameter" "app_context" {
  name        = "/${var.project_name}/app-context"
  description = "Context information about Okta apps and groups for AI bot"
  type        = "SecureString"
  value       = "Placeholder - will be updated by context-updater Lambda"

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.project_name}-app-context"
      Description = "Auto-updated by context-updater Lambda"
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

# Okta App Group Lambda - context updater
module "okta_app_group_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-okta-app-group-updater"
  handler       = "index.lambda_handler"
  runtime       = "python3.12"
  memory_size   = 512
  timeout       = 300
  aws_region    = var.aws_region

  environment_variables = {
    SSM_PARAMETER_NAME        = aws_ssm_parameter.app_context.name
    OKTA_CREDENTIALS_SSM_NAME = aws_ssm_parameter.okta_credentials.name
    LOG_LEVEL                 = "INFO"
  }

  iam_policy_statements = [
    # SSM parameter write access for app context
    {
      Effect = "Allow"
      Action = [
        "ssm:PutParameter",
        "ssm:GetParameter",
        "ssm:GetParameters"
      ]
      Resource = aws_ssm_parameter.app_context.arn
    },
    # SSM parameter read access for Okta credentials
    {
      Effect = "Allow"
      Action = [
        "ssm:GetParameter",
        "ssm:GetParameters"
      ]
      Resource = aws_ssm_parameter.okta_credentials.arn
    }
  ]
}

# DynamoDB tables for Hagrid Slack bot
module "dynamodb_tables" {
  source = "./modules/dynamodb_tables"

  project_name = var.project_name
}

# Event Handler Lambda for Slack webhook events
module "event_handler_lambda" {
  source = "./modules/lambda"

  function_name = "${var.project_name}-event-handler"
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  memory_size   = 128
  timeout       = 10
  aws_region    = var.aws_region

  environment_variables = {
    CONVERSATIONS_TABLE        = module.dynamodb_tables.conversations_table_name
    ACCESS_REQUESTS_TABLE      = module.dynamodb_tables.access_requests_table_name
    APPROVAL_MESSAGES_TABLE    = module.dynamodb_tables.approval_messages_table_name
    SSM_PARAMETER_NAME         = aws_ssm_parameter.app_context.name
    OKTA_CREDENTIALS_SSM_NAME  = aws_ssm_parameter.okta_credentials.name
    LOG_LEVEL                  = "INFO"
  }

  iam_policy_statements = [
    # Lambda invoke permissions for calling other Hagrid Lambdas
    {
      Effect = "Allow"
      Action = [
        "lambda:InvokeFunction"
      ]
      Resource = "arn:aws:lambda:${var.aws_region}:*:function:${var.project_name}-*"
    },
    # SSM parameter read access
    {
      Effect = "Allow"
      Action = [
        "ssm:GetParameter",
        "ssm:GetParameters"
      ]
      Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/${var.project_name}/*"
    },
    # DynamoDB read/write access for all Hagrid tables
    {
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ]
      Resource = [
        module.dynamodb_tables.conversations_table_arn,
        module.dynamodb_tables.access_requests_table_arn,
        module.dynamodb_tables.approval_messages_table_arn,
        "${module.dynamodb_tables.conversations_table_arn}/index/*",
        "${module.dynamodb_tables.access_requests_table_arn}/index/*",
        "${module.dynamodb_tables.approval_messages_table_arn}/index/*"
      ]
    }
  ]
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
