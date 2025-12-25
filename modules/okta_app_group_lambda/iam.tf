# IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-okta-app-group-lambda-role"

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
    Name = "${var.project_name}-okta-app-group-lambda-role"
  }
}

# Policy for SSM Parameter Store access
resource "aws_iam_role_policy" "lambda_ssm" {
  name = "${var.project_name}-okta-lambda-ssm"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:PutParameter",
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = var.ssm_parameter_arn
      }
    ]
  })
}

# Policy for SSM Parameter Store access (to read Okta credentials)
resource "aws_iam_role_policy" "lambda_okta_credentials" {
  name = "${var.project_name}-okta-lambda-credentials"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = var.okta_credentials_ssm_arn
      }
    ]
  })
}
