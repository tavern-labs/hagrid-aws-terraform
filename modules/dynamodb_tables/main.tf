# DynamoDB table for storing conversation history
resource "aws_dynamodb_table" "conversations" {
  name         = "${var.project_name}-conversations"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "conversation_id"
  range_key    = "message_index"

  attribute {
    name = "conversation_id"
    type = "S"
  }

  attribute {
    name = "message_index"
    type = "N"
  }

  ttl {
    enabled        = true
    attribute_name = "expires_at"
  }

  tags = {
    Name    = "${var.project_name}-conversations"
    Purpose = "Store message history for AI context preservation"
  }
}

# DynamoDB table for tracking access requests
resource "aws_dynamodb_table" "access_requests" {
  name         = "${var.project_name}-access-requests"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "request_id"

  attribute {
    name = "request_id"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  # GSI for querying requests by user
  global_secondary_index {
    name            = "user-requests-index"
    hash_key        = "user_id"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  # GSI for querying by status
  global_secondary_index {
    name            = "status-index"
    hash_key        = "status"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name    = "${var.project_name}-access-requests"
    Purpose = "Track all access requests and their status"
  }
}

# DynamoDB table for tracking approval messages
resource "aws_dynamodb_table" "approval_messages" {
  name         = "${var.project_name}-approval-messages"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "approval_message_id"

  attribute {
    name = "approval_message_id"
    type = "S"
  }

  attribute {
    name = "request_id"
    type = "S"
  }

  attribute {
    name = "approver_email"
    type = "S"
  }

  # GSI for getting all approvals for a request
  global_secondary_index {
    name            = "request-approvals-index"
    hash_key        = "request_id"
    range_key       = "approver_email"
    projection_type = "ALL"
  }

  tags = {
    Name    = "${var.project_name}-approval-messages"
    Purpose = "Track approval DMs sent to approvers"
  }
}
