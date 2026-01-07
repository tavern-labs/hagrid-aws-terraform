# Conversations table outputs
output "conversations_table_name" {
  description = "Name of the conversations DynamoDB table"
  value       = aws_dynamodb_table.conversations.name
}

output "conversations_table_arn" {
  description = "ARN of the conversations DynamoDB table"
  value       = aws_dynamodb_table.conversations.arn
}

# Access requests table outputs
output "access_requests_table_name" {
  description = "Name of the access requests DynamoDB table"
  value       = aws_dynamodb_table.access_requests.name
}

output "access_requests_table_arn" {
  description = "ARN of the access requests DynamoDB table"
  value       = aws_dynamodb_table.access_requests.arn
}

# Approval messages table outputs
output "approval_messages_table_name" {
  description = "Name of the approval messages DynamoDB table"
  value       = aws_dynamodb_table.approval_messages.name
}

output "approval_messages_table_arn" {
  description = "ARN of the approval messages DynamoDB table"
  value       = aws_dynamodb_table.approval_messages.arn
}
