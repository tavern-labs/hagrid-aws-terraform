# Reusable Lambda function module
# NOTE: Code, runtime, layers, and configuration are managed manually or via CI/CD
# Terraform only manages the Lambda shell, IAM roles, and infrastructure
# See lifecycle.ignore_changes block for details on what is NOT managed by Terraform

# Lambda function
resource "aws_lambda_function" "function" {
  function_name = var.function_name
  role          = var.role_arn != null ? var.role_arn : aws_iam_role.lambda_role[0].arn
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size

  # Minimal placeholder code - update manually in console or via CI/CD
  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  environment {
    variables = var.environment_variables
  }

  lifecycle {
    ignore_changes = [
      # Code deployment - managed manually or via CI/CD
      filename,
      source_code_hash,
      s3_bucket,
      s3_key,
      s3_object_version,
      image_uri,

      # Runtime configuration - protect manual updates
      runtime,
      layers,

      # Environment variables - may be updated manually
      environment,

      # Performance tuning - may be adjusted in production
      memory_size,
      timeout,

      # Other configs that may be manually adjusted
      reserved_concurrent_executions,
      ephemeral_storage,
    ]
  }

  tags = {
    Name = var.function_name
  }
}

# Minimal placeholder code for initial deployment
resource "local_file" "placeholder_code" {
  filename = "${path.module}/placeholder/${var.function_name}/index.py"
  content  = <<-EOT
    def lambda_handler(event, context):
        return {'statusCode': 200, 'body': 'Placeholder - update code manually or via CI/CD'}
  EOT
}

data "archive_file" "placeholder" {
  type        = "zip"
  output_path = "${path.module}/placeholder/${var.function_name}.zip"

  source {
    content  = local_file.placeholder_code.content
    filename = "index.py"
  }
}
