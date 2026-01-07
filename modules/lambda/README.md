# Lambda Module

Enterprise-grade Lambda function module with centralized IAM control.

## Security Pattern

This module follows security best practices used by Netflix, Stripe, Coinbase, and other enterprise companies:

- **No inline IAM creation** - All IAM roles must be defined in root `iam.tf`
- **Centralized security control** - Security teams review all IAM in one place
- **Enforced compliance** - Developers cannot create custom IAM policies
- **Code protection** - Lifecycle ignores prevent Terraform from overwriting deployed code

## Usage

### 1. Define IAM Role in Root iam.tf

```hcl
# iam.tf
resource "aws_iam_role" "my_lambda_role" {
  name = "my-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "my_lambda_cloudwatch" {
  name = "my-lambda-cloudwatch"
  role = aws_iam_role.my_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/my-function:*"
    }]
  })
}
```

### 2. Use Module with External Role

```hcl
# main.tf
module "my_lambda" {
  source = "./modules/lambda"

  function_name = "my-function"
  handler       = "index.handler"
  runtime       = "python3.12"
  role_arn      = aws_iam_role.my_lambda_role.arn  # Required!
  aws_region    = "us-east-1"

  environment_variables = {
    TABLE_NAME = "my-table"
  }
}
```

## Required Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `function_name` | string | Name of the Lambda function |
| `role_arn` | string | **Required** - ARN of IAM role from root iam.tf |
| `aws_region` | string | AWS region |

## Optional Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `handler` | string | `index.lambda_handler` | Lambda handler |
| `runtime` | string | `python3.12` | Lambda runtime |
| `memory_size` | number | `128` | Memory in MB |
| `timeout` | number | `10` | Timeout in seconds |
| `environment_variables` | map(string) | `{}` | Environment variables |

## Outputs

| Output | Description |
|--------|-------------|
| `function_arn` | ARN of the Lambda function |
| `function_name` | Name of the Lambda function |
| `invoke_arn` | Invoke ARN for API Gateway integration |
| `role_arn` | ARN of the execution role |
| `role_name` | Name of the execution role |

## Code Deployment

This module creates a Lambda shell with placeholder code. Deploy your actual code via:

1. **AWS Console** - Upload manually
2. **AWS CLI** - `aws lambda update-function-code`
3. **CI/CD Pipeline** - Automated deployment

The module's `lifecycle.ignore_changes` block ensures Terraform never overwrites your deployed code, runtime, layers, or configuration.

## Why This Pattern?

### Enterprise Benefits

✅ **Security Audit** - All IAM in one file for quarterly compliance reviews
✅ **CODEOWNERS** - Require security team approval on `iam.tf`
✅ **Blast Radius** - Limit who can modify IAM vs application config
✅ **Compliance** - SOC2/ISO auditors prefer centralized IAM
✅ **Reusability** - Share roles across multiple resources

### Developer Benefits

✅ **Clear Contract** - Know exactly what permissions are granted
✅ **Self-Service** - Deploy Lambdas without waiting for IAM
✅ **No Surprises** - Can't accidentally create overprivileged roles

## Examples

See `../../iam.tf` for real-world examples of IAM roles for:
- Event Handler Lambda (DynamoDB, SSM, Lambda invoke)
- Okta Lambda (SSM read/write)
