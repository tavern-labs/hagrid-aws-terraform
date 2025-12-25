# Okta App Group Lambda Module

Terraform module that creates a Lambda function to pull Okta app group data and store it in SSM Parameter Store.

## Resources Created

- **Lambda Function**: Python 3.12 runtime with placeholder code
- **IAM Role**: Execution role with permissions for SSM Parameter Store and Secrets Manager

The Lambda is created with minimal placeholder code. You can update the code manually in the AWS Console for testing.

## Usage

```hcl
module "okta_app_group_lambda" {
  source = "./modules/okta_app_group_lambda"

  project_name       = var.project_name
  aws_region         = var.aws_region
  ssm_parameter_name = aws_ssm_parameter.app_context.name
  ssm_parameter_arn  = aws_ssm_parameter.app_context.arn
  okta_secret_arn    = aws_secretsmanager_secret.okta_credentials.arn
  okta_secret_name   = aws_secretsmanager_secret.okta_credentials.name

  # Optional
  lambda_timeout     = 300
  lambda_memory_size = 512
}
```

## Updating Lambda Code

The Lambda is created with placeholder code. To update:

1. Go to AWS Console → Lambda → `hagrid-okta-app-group-updater`
2. Update the code in the code editor or upload a .zip file
3. Terraform won't overwrite your manual changes (lifecycle rule ignores code updates)

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `project_name` | Project name for resource naming | `string` | Yes |
| `aws_region` | AWS region | `string` | Yes |
| `ssm_parameter_name` | SSM parameter name | `string` | Yes |
| `ssm_parameter_arn` | SSM parameter ARN | `string` | Yes |
| `okta_secret_arn` | Secrets Manager secret ARN | `string` | Yes |
| `okta_secret_name` | Secrets Manager secret name | `string` | Yes |
| `lambda_timeout` | Timeout in seconds | `number` | No (default: 300) |
| `lambda_memory_size` | Memory in MB | `number` | No (default: 512) |

## Outputs

| Name | Description |
|------|-------------|
| `lambda_function_arn` | Lambda function ARN |
| `lambda_function_name` | Lambda function name |
| `lambda_role_arn` | IAM role ARN |
| `lambda_role_name` | IAM role name |

## Lambda Configuration

- **Runtime**: Python 3.12
- **Handler**: `index.lambda_handler`
- **Environment Variables**:
  - `SSM_PARAMETER_NAME`: SSM parameter to update
  - `OKTA_SECRET_NAME`: Secrets Manager secret with Okta credentials
  - `LOG_LEVEL`: Logging level (INFO)

## IAM Permissions

The Lambda execution role has permissions to:
- Read from Secrets Manager (Okta credentials)
- Read/write to SSM Parameter Store (app context)
