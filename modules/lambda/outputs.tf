output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.function.arn
}

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.function.function_name
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function (for API Gateway integration)"
  value       = aws_lambda_function.function.invoke_arn
}

output "role_arn" {
  description = "ARN of the Lambda execution role"
  value       = var.role_arn != null ? var.role_arn : aws_iam_role.lambda_role[0].arn
}

output "role_name" {
  description = "Name of the Lambda execution role"
  value       = var.role_arn != null ? split("/", var.role_arn)[1] : aws_iam_role.lambda_role[0].name
}
