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
