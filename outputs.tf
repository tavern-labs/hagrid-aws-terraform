output "app_context_parameter_name" {
  description = "Name of the SSM parameter storing app context"
  value       = aws_ssm_parameter.app_context.name
}

output "app_context_parameter_arn" {
  description = "ARN of the SSM parameter storing app context"
  value       = aws_ssm_parameter.app_context.arn
}
