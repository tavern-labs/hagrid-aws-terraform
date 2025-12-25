# Lambda function
resource "aws_lambda_function" "okta_app_group_updater" {
  function_name    = "${var.project_name}-okta-app-group-updater"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.lambda_handler"
  runtime         = "python3.12"
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size

  # Minimal placeholder code - update manually in console
  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  environment {
    variables = {
      SSM_PARAMETER_NAME = var.ssm_parameter_name
      OKTA_SECRET_NAME   = var.okta_secret_name
      LOG_LEVEL          = "INFO"
    }
  }

  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash
    ]
  }

  tags = {
    Name = "${var.project_name}-okta-app-group-updater"
  }
}

# Minimal placeholder code for initial deployment
resource "local_file" "placeholder_code" {
  filename = "${path.module}/placeholder/index.py"
  content  = <<-EOT
    def lambda_handler(event, context):
        return {'statusCode': 200, 'body': 'Placeholder - update code manually'}
  EOT
}

data "archive_file" "placeholder" {
  type        = "zip"
  output_path = "${path.module}/placeholder.zip"

  source {
    content  = local_file.placeholder_code.content
    filename = "index.py"
  }
}
