# IAM role for Lambda execution
# Only created if role_arn is not provided (for backward compatibility)
resource "aws_iam_role" "lambda_role" {
  count = var.role_arn == null ? 1 : 0
  name  = "${var.function_name}-role"

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

  tags = {
    Name = "${var.function_name}-role"
  }
}

# CloudWatch Logs policy (required for all Lambdas)
# Only created if role_arn is not provided
resource "aws_iam_role_policy" "cloudwatch_logs" {
  count = var.role_arn == null ? 1 : 0
  name  = "${var.function_name}-cloudwatch-logs"
  role  = aws_iam_role.lambda_role[0].id

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
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${var.function_name}:*"
      }
    ]
  })
}

# Custom IAM policy for additional permissions
# Only created if role_arn is not provided
resource "aws_iam_role_policy" "custom_policy" {
  count = var.role_arn == null && length(var.iam_policy_statements) > 0 ? 1 : 0
  name  = "${var.function_name}-custom-policy"
  role  = aws_iam_role.lambda_role[0].id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = var.iam_policy_statements
  })
}
