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

# Okta App Group Lambda module
module "okta_app_group_lambda" {
  source = "./modules/okta_app_group_lambda"

  project_name              = var.project_name
  aws_region                = var.aws_region
  ssm_parameter_name        = aws_ssm_parameter.app_context.name
  ssm_parameter_arn         = aws_ssm_parameter.app_context.arn
  okta_credentials_ssm_name = aws_ssm_parameter.okta_credentials.name
  okta_credentials_ssm_arn  = aws_ssm_parameter.okta_credentials.arn

  # Optional: customize Lambda settings
  lambda_timeout     = 300
  lambda_memory_size = 512
}
