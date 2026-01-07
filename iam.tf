# ============================================================================
# IAM Roles and Policies for Hagrid Slack Bot
# ============================================================================
# All IAM resources are defined here for security audit and review.
# This separation allows security teams to review IAM changes independently
# from application infrastructure changes.
# ============================================================================

# ----------------------------------------------------------------------------
# Okta App Group Updater Lambda Role
# ----------------------------------------------------------------------------

resource "aws_iam_role" "okta_lambda_role" {
  name = "${var.project_name}-okta-app-group-updater-role"

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
      Name    = "${var.project_name}-okta-lambda-role"
      Purpose = "Execution role for Okta app group context updater Lambda"
    }
  )
}

# CloudWatch Logs policy for Okta Lambda
resource "aws_iam_role_policy" "okta_lambda_cloudwatch" {
  name = "${var.project_name}-okta-lambda-cloudwatch"
  role = aws_iam_role.okta_lambda_role.id

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
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${var.project_name}-okta-app-group-updater:*"
      }
    ]
  })
}

# SSM Parameter access for Okta Lambda
resource "aws_iam_role_policy" "okta_lambda_ssm" {
  name = "${var.project_name}-okta-lambda-ssm"
  role = aws_iam_role.okta_lambda_role.id

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
