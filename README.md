# Hagrid AWS Infrastructure

Terraform configuration for the Hagrid Slack bot - an AI-powered access request and approval system integrated with Okta.

## Architecture Overview

Hagrid is a serverless application that processes Slack webhook events, manages conversational AI flows, handles approval workflows, and provisions Okta group access. The infrastructure is designed following enterprise security patterns with centralized IAM, least-privilege permissions, and separation of infrastructure from application code.

## Project Structure

```
hagrid-aws-terraform/
├── main.tf              # Core infrastructure (Lambda modules, API Gateway, SSM parameters)
├── iam.tf               # Centralized IAM roles and policies (security-first design)
├── outputs.tf           # Terraform outputs for integration with other systems
├── variables.tf         # Input variables with sensible defaults
├── provider.tf          # AWS provider configuration
├── backend.tf           # S3 backend for remote state
├── modules/
│   ├── lambda/          # Reusable Lambda module with lifecycle protection
│   └── dynamodb_tables/ # DynamoDB tables for conversation state
└── .github/
    └── workflows/       # GitHub Actions for Terraform CI/CD
```

## Design Decisions

### 1. Lambda Functions: Module Pattern with Lifecycle Protection

**Pattern**: All Lambda functions use a reusable module (`modules/lambda/`) with comprehensive lifecycle protection.

**Why**:
- **Separation of Concerns**: Terraform manages infrastructure shell, GitHub Actions deploys code
- **Placeholder Code**: Module creates minimal Python placeholder for initial deployment
- **Lifecycle Ignore**: Prevents Terraform from overwriting deployed code
  ```hcl
  ignore_changes = [
    filename, source_code_hash, s3_bucket, s3_key, s3_object_version,
    runtime, layers, environment, memory_size, timeout, ...
  ]
  ```
- **Flexibility**: Code deployments happen independently via CI/CD without terraform apply

**Lambda Functions**:
- `hagrid-event-handler`: Slack webhook receiver (256MB, 30s) - API Gateway entry point
- `hagrid-conversation-manager`: AI/NLP intent detection (512MB, 60s) - Conversation state engine
- `hagrid-approval-manager`: Approval DM sender (256MB, 30s) - Orchestrates approval flow
- `hagrid-okta-provisioner`: Okta group provisioner (256MB, 30s) - Executes approved access grants
- `hagrid-catalog-builder`: Context builder (512MB, 300s) - Updates Okta app/group catalog

### 2. IAM: Centralized Security-First Design

**Pattern**: All IAM resources defined in `iam.tf` as explicit, per-function policies.

**Why**:
- **Security Review**: Single file for security teams to audit all permissions
- **Least Privilege**: Each function has exactly the permissions it needs, no more
- **Blast Radius**: Changing one function's permissions doesn't affect others
- **Explicit > DRY**: Intentional "redundancy" for security isolation
- **Mirrors Netflix/Stripe**: Industry pattern for compliance-driven organizations

**IAM Structure Per Lambda**:
1. Execution role with Lambda assume policy
2. CloudWatch Logs policy (scoped to specific log group)
3. Function-specific policies (DynamoDB, SSM, Lambda invoke, etc.)

**Permission Scoping Examples**:
- Event Handler: Full DynamoDB + SSM read + Lambda invoke (all functions)
- Conversation Manager: Full DynamoDB + SSM read (app context)
- Approval Manager: DynamoDB + Lambda invoke (okta-provisioner only)
- Okta Provisioner: SSM read (Okta credentials only - most restrictive)
- Catalog Builder: SSM read/write (app context) + Okta credentials

### 3. DynamoDB: Module-Based Table Management

**Pattern**: DynamoDB tables defined in `modules/dynamodb_tables/` module.

**Tables**:
- `hagrid-conversations`: Slack conversation state and history
- `hagrid-access-requests`: Access request tracking and status
- `hagrid-approval-messages`: Approval message metadata for response handling

**Why Module**:
- **Reusability**: Tables can be referenced across multiple Lambda functions
- **Consistent Configuration**: All tables share common settings (billing mode, encryption)
- **Centralized Management**: Table schema changes in one place

### 4. API Gateway: Regional REST API with CloudWatch Logging

**Pattern**: REST API with explicit stage management and account-level CloudWatch setup.

**Resources**:
- REST API: Regional endpoint type
- Resources: `/slack/events` path structure
- Integration: AWS_PROXY to event-handler Lambda
- Deployment: SHA1-based triggers for automatic redeployment
- Stage: `prod` with CloudWatch access logs
- Account Settings: One-time CloudWatch IAM role (shared across all APIs)

**Why This Design**:
- **Account-Level Role**: `api-gateway-cloudwatch-global` shared across all API Gateways (AWS requirement)
- **Explicit Dependencies**: Stage depends on account settings to prevent deployment failures
- **Redeployment Triggers**: SHA1 hash ensures infrastructure changes trigger new deployments
- **Access Logs**: Detailed CloudWatch logging for debugging and monitoring

### 5. GitHub Actions OIDC: Keyless Lambda Deployment

**Pattern**: OIDC federation for GitHub Actions to deploy Lambda code without static credentials.

**Resources**:
- OIDC Provider: `token.actions.githubusercontent.com` (data source - already exists)
- IAM Role: `hagrid-lambda-deploy-role`
- Policy: Least-privilege (only `lambda:UpdateFunctionCode`)

**Why OIDC**:
- **No Static Credentials**: No AWS access keys stored in GitHub secrets
- **Scoped Access**: Only main branch of `tavern-labs/hagrid-lambdas` can deploy
- **Least Privilege**: Can only update function code, not modify infrastructure
- **Audit Trail**: CloudTrail logs show exact GitHub commit/branch that deployed

**Restrictions**:
- Repository: `tavern-labs/hagrid-lambdas`
- Branch: `main` only
- Permissions: `lambda:UpdateFunctionCode`, `lambda:GetFunction` (read-only for verification)
- Resources: `hagrid-*` functions only

### 6. SSM Parameter Store: Secure Configuration Management

**Pattern**: SecureString parameters with lifecycle ignore for runtime updates.

**Parameters**:
- `/hagrid/app-context`: Okta apps/groups catalog (updated by catalog-builder)
- `/hagrid/okta-credentials`: Okta API credentials (manually configured)

**Why SSM**:
- **Encryption**: Automatic KMS encryption for sensitive data
- **Runtime Updates**: `lifecycle { ignore_changes = [value] }` allows Lambda updates
- **Versioning**: SSM maintains version history for rollback
- **IAM Integration**: Fine-grained access control per function

## Deployment Workflow

### Infrastructure (Terraform)

```bash
# Initialize
terraform init

# Plan changes
terraform plan

# Apply infrastructure
terraform apply
```

**CI/CD**: GitHub Actions automatically runs on pushes to main branch (see `.github/workflows/`)

### Lambda Code (GitHub Actions)

Lambda function code is deployed separately via GitHub Actions using OIDC:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.LAMBDA_DEPLOY_ROLE_ARN }}
    aws-region: us-east-2

- name: Deploy Lambda
  run: |
    aws lambda update-function-code \
      --function-name hagrid-event-handler \
      --zip-file fileb://function.zip
```

## Key Outputs

```hcl
# API Gateway
api_gateway_url                    # Slack webhook URL
api_gateway_id                     # API Gateway ID

# Lambda Functions
event_handler_function_arn         # Event handler ARN
conversation_manager_function_arn  # Conversation manager ARN
approval_manager_function_arn      # Approval manager ARN
okta_provisioner_function_arn      # Okta provisioner ARN
catalog_builder_function_arn       # Catalog builder ARN

# DynamoDB Tables
conversations_table_name           # Conversations table
access_requests_table_name         # Access requests table
approval_messages_table_name       # Approval messages table

# GitHub Actions
github_lambda_deploy_role_arn      # OIDC role ARN (add to GitHub secrets)
```

## Security Best Practices

1. **Least Privilege IAM**: Each Lambda has only the permissions it needs
2. **Centralized IAM**: All security policies in one file for audit
3. **No Hardcoded Secrets**: Okta credentials in SSM Parameter Store
4. **OIDC Authentication**: No static AWS credentials in GitHub
5. **Encrypted Parameters**: All SSM parameters use KMS encryption
6. **CloudWatch Logging**: Comprehensive logging for all Lambda functions
7. **API Gateway Logging**: Request/response logging for debugging

## State Management

- **Backend**: S3 bucket with state locking
- **Encryption**: State files encrypted at rest
- **Locking**: DynamoDB lock file prevents concurrent modifications
- **Remote State**: Shared across team via S3 backend

## Development Guidelines

### Adding a New Lambda Function

1. **Define module in `main.tf`**:
   ```hcl
   module "new_function_lambda" {
     source        = "./modules/lambda"
     function_name = "${var.project_name}-new-function"
     role_arn      = aws_iam_role.new_function_lambda_role.arn
     # ... other config
   }
   ```

2. **Create IAM role in `iam.tf`**:
   ```hcl
   resource "aws_iam_role" "new_function_lambda_role" {
     name = "${var.project_name}-new-function-role"
     # ... assume role policy
   }

   resource "aws_iam_role_policy" "new_function_cloudwatch" {
     # ... CloudWatch policy
   }

   # Add function-specific policies (DynamoDB, SSM, etc.)
   ```

3. **Add outputs in `outputs.tf`**:
   ```hcl
   output "new_function_function_arn" {
     value = module.new_function_lambda.function_arn
   }
   ```

### Modifying Lambda Permissions

Always modify permissions in `iam.tf`, not in the Lambda module. This maintains the centralized security review pattern.

## Common Operations

### Viewing Current Infrastructure

```bash
terraform show
```

### Importing Existing Resources

```bash
# Example: Import existing OIDC provider
terraform import aws_iam_openid_connect_provider.github_actions \
  arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com
```

### Destroying Infrastructure

```bash
terraform destroy
```

**Warning**: This will delete all Lambda functions, DynamoDB tables (and their data), and API Gateway. Make sure you have backups.

## Monitoring and Debugging

- **CloudWatch Logs**: `/aws/lambda/hagrid-*` log groups
- **API Gateway Logs**: `/aws/apigateway/hagrid-api`
- **X-Ray Tracing**: Can be enabled in Lambda environment variables
- **DynamoDB Metrics**: Available in CloudWatch console

## Repository Maintenance

- **Terraform Version**: `>= 1.0`
- **AWS Provider**: `~> 5.0`
- **State Backend**: S3 bucket `tfstate-tavernlabs-03711579496081468369`
- **Region**: `us-east-2` (Ohio)

## Contributing

1. Create a feature branch from main
2. Make changes following existing patterns
3. Run `terraform plan` to verify changes
4. Submit PR for review
5. After approval, merge triggers automatic `terraform apply`

## License

Proprietary - Tavern Labs
