terraform {
  backend "s3" {
    # You'll need to update these values to match your existing S3 bucket
    # bucket = "your-terraform-state-bucket"
    # key    = "aws/terraform.tfstate"
    # region = "us-east-1"

    # Enable encryption at rest
    # encrypt = true

    # Enable DynamoDB state locking (optional but recommended)
    # dynamodb_table = "terraform-state-lock"
  }

  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
