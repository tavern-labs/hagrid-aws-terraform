# ============================================================================
# IAM Roles and Policies for Hagrid Slack Bot
# ============================================================================
# All IAM resources are defined here for security audit and review.
# This separation allows security teams to review IAM changes independently
# from application infrastructure changes.
#
# SECURITY PATTERN: Enterprise-Grade Centralized IAM
# - Lambda modules REQUIRE role_arn parameter (no fallback IAM creation)
# - All roles and policies defined in this file only
# - Enforces security review workflow and compliance standards
# - Mirrors patterns used at Netflix, Stripe, Coinbase, OpenAI, etc.
#
# To add a new Lambda:
# 1. Define IAM role in this file
# 2. Define required policies in this file
# 3. Pass role ARN to lambda module
# ============================================================================

# ----------------------------------------------------------------------------
# Catalog Builder Lambda Role
# ----------------------------------------------------------------------------

resource "aws_iam_role" "catalog_builder_lambda_role" {
  name = "${var.project_name}-catalog-builder-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.project_name}-catalog-builder-lambda-role"
      Purpose = "Execution role for catalog builder Lambda"
    }
  )
}

# CloudWatch Logs policy for Catalog Builder Lambda
resource "aws_iam_role_policy" "catalog_builder_lambda_cloudwatch" {
  name = "${var.project_name}-catalog-builder-lambda-cloudwatch"
  role = aws_iam_role.catalog_builder_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${var.project_name}-catalog-builder:*"
      }
    ]
  })
}

# SSM Parameter access for Catalog Builder Lambda
resource "aws_iam_role_policy" "catalog_builder_lambda_ssm" {
  name = "${var.project_name}-catalog-builder-lambda-ssm"
  role = aws_iam_role.catalog_builder_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Write access to app context parameter
      {
        Effect = "Allow"
        Action = [
          "ssm:PutParameter",
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = aws_ssm_parameter.app_context.arn
      },
      # Read access to Okta credentials
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = aws_ssm_parameter.okta_credentials.arn
      }
    ]
  })
}

# ----------------------------------------------------------------------------
# Event Handler Lambda Role
# ----------------------------------------------------------------------------

resource "aws_iam_role" "event_handler_lambda_role" {
  name = "${var.project_name}-event-handler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.project_name}-event-handler-role"
      Purpose = "Execution role for Slack webhook event handler Lambda"
    }
  )
}

# CloudWatch Logs policy for Event Handler Lambda
resource "aws_iam_role_policy" "event_handler_cloudwatch" {
  name = "${var.project_name}-event-handler-cloudwatch"
  role = aws_iam_role.event_handler_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${var.project_name}-event-handler:*"
      }
    ]
  })
}

# Lambda invoke policy for Event Handler
resource "aws_iam_role_policy" "event_handler_lambda_invoke" {
  name = "${var.project_name}-event-handler-lambda-invoke"
  role = aws_iam_role.event_handler_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "arn:aws:lambda:${var.aws_region}:*:function:${var.project_name}-*"
      }
    ]
  })
}

# SSM Parameter read access for Event Handler
resource "aws_iam_role_policy" "event_handler_ssm" {
  name = "${var.project_name}-event-handler-ssm"
  role = aws_iam_role.event_handler_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/${var.project_name}/*"
      }
    ]
  })
}

# DynamoDB access for Event Handler
resource "aws_iam_role_policy" "event_handler_dynamodb" {
  name = "${var.project_name}-event-handler-dynamodb"
  role = aws_iam_role.event_handler_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
  })
}

# ----------------------------------------------------------------------------
# API Gateway CloudWatch Role (Account-Level)
# ----------------------------------------------------------------------------
# This is a one-time account setting required for API Gateway stage logging.
# The role is intentionally not prefixed with the project name since it's a
# global account resource shared across all API Gateways in the AWS account.

resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "api-gateway-cloudwatch-global"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

# Attach AWS managed policy for API Gateway CloudWatch logging
resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  role       = aws_iam_role.api_gateway_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# ----------------------------------------------------------------------------
# GitHub Actions OIDC Federation for Lambda Deployments
# ----------------------------------------------------------------------------
# This section manages OIDC federation between GitHub Actions and AWS,
# allowing GitHub workflows to assume IAM roles without static credentials.

# Data source to get AWS account ID
data "aws_caller_identity" "current" {}

# GitHub OIDC Provider - reference existing provider
# Uses data source since the provider already exists in the AWS account
data "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

# IAM Role for GitHub Actions Lambda Deployment
# This role allows GitHub Actions to deploy Lambda function code ONLY.
# It cannot modify infrastructure, only update function code.

resource "aws_iam_role" "github_lambda_deploy" {
  name = "${var.project_name}-lambda-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Only allow from main branch of the hagrid-lambdas repo
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_lambda_repo}:ref:refs/heads/main"
          }
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.project_name}-lambda-deploy-role"
      Purpose = "GitHub Actions role for Lambda code deployment"
    }
  )
}

# IAM Policy for Lambda Code Deployment
# Least-privilege policy: ONLY allows updating Lambda function code,
# not infrastructure changes.

resource "aws_iam_role_policy" "github_lambda_deploy" {
  name = "${var.project_name}-lambda-deploy-policy"
  role = aws_iam_role.github_lambda_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration"
        ]
        Resource = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-*"
      }
    ]
  })
}
