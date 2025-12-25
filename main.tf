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

# Secrets Manager secret to store Okta API credentials
resource "aws_secretsmanager_secret" "okta_credentials" {
  name        = "${var.project_name}/okta-credentials"
  description = "Okta API credentials for app group context updater"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-okta-credentials"
    }
  )
}

# Placeholder secret version - you need to update this with real credentials
resource "aws_secretsmanager_secret_version" "okta_credentials" {
  secret_id = aws_secretsmanager_secret.okta_credentials.id
  secret_string = jsonencode({
    domain    = "your-domain.okta.com"
    api_token = "your-api-token-here"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Okta App Group Lambda module
module "okta_app_group_lambda" {
  source = "./modules/okta_app_group_lambda"

  project_name       = var.project_name
  aws_region         = var.aws_region
  ssm_parameter_name = aws_ssm_parameter.app_context.name
  ssm_parameter_arn  = aws_ssm_parameter.app_context.arn
  okta_secret_arn    = aws_secretsmanager_secret.okta_credentials.arn
  okta_secret_name   = aws_secretsmanager_secret.okta_credentials.name

  # Optional: customize Lambda settings
  lambda_timeout     = 300
  lambda_memory_size = 512
}
