# Hagrid AWS Infrastructure

Terraform configuration for the Hagrid Slack bot - an AI-powered access request and approval system integrated with Okta.

## Architecture Overview

Hagrid is a serverless application that processes Slack webhook events, manages conversational AI flows, handles approval workflows, and provisions Okta group access. The infrastructure is designed following enterprise security patterns with centralized IAM, least-privilege permissions, and separation of infrastructure from application code.

## Project Structure

```
hagrid-aws-terraform/
├── main.tf              # Core infrastructure (Lambda modules, API Gateway, S3, SSM parameters)
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
- `hagrid-catalog-builder`: Context builder (512MB, 300s) - Updates Okta app/group catalog (consider EventBridge schedule for automatic updates)

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
- Conversation Manager: Full DynamoDB + S3 read (catalog) + SSM read
- Approval Manager: DynamoDB + S3 read (catalog) + SSM read + Lambda invoke (okta-provisioner)
- Okta Provisioner: SSM read (Okta credentials only - most restrictive)
- Catalog Builder: S3 write (catalog) + SSM read (Okta credentials)

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

### 6. S3 Bucket: Catalog Storage

**Pattern**: Versioned S3 bucket with public access blocking for storing Okta catalog data.

**Bucket**: `hagrid-catalog-{random-id}` - Stores Okta apps/groups catalog (written by catalog-builder, read by conversation-manager and approval-manager)

**Why S3 over SSM**:
- **Size Limits**: SSM parameters limited to 8KB; S3 supports much larger catalogs
- **Versioning**: Built-in version control for catalog rollback
- **Cost**: More cost-effective for larger data
- **Performance**: Better suited for large JSON payloads

**Security**:
- **Public Access Blocked**: All public access explicitly disabled
- **Versioning Enabled**: Maintains history of catalog changes
- **IAM Scoped**: Only catalog-builder can write, only conversation-manager and approval-manager can read

### 7. SSM Parameter Store: Secure Configuration Management

**Pattern**: SecureString parameters with lifecycle ignore for runtime updates.

**Parameters**:
- `/hagrid/okta-credentials`: Okta API credentials (SecureString)
- `/hagrid/slack-signing-secret`: Slack webhook verification secret (SecureString)
- `/hagrid/slack-bot-token`: Slack bot OAuth token (SecureString)
- `/hagrid/gemini-api-key`: Google Gemini API key for AI processing (SecureString)
- `/hagrid/system-prompt`: AI system prompt configuration (String)

**Why SSM**:
- **Encryption**: Automatic KMS encryption for SecureString parameters
- **Runtime Updates**: `lifecycle { ignore_changes = [value] }` allows manual updates without Terraform changes
- **Versioning**: SSM maintains version history for rollback
- **IAM Integration**: Fine-grained access control per function

**CI/CD**: GitHub Actions automatically runs on pushes to main branch (see `.github/workflows/`)

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

## TODOs: Infrastructure Improvements

### Security & Compliance

- [ ] **DynamoDB Backups**: Enable point-in-time recovery (PITR) for all tables with automated backup policies
- [ ] **S3 KMS Encryption**: Add customer-managed KMS keys for S3 catalog bucket encryption
- [ ] **S3 Lifecycle Policies**: Implement lifecycle rules to transition old catalog versions to cheaper storage
- [ ] **API Gateway Rate Limiting**: Add throttling and usage plans to prevent abuse
- [ ] **VPC Integration**: Move Lambda functions into VPC for network isolation (requires VPC endpoints for AWS services)
- [ ] **Secret Rotation**: Implement automated rotation for Okta credentials, Slack tokens, and API keys
- [ ] **CloudTrail Logging**: Enable CloudTrail for audit logging (if required for compliance)

### Automation & Efficiency

- [ ] **EventBridge Schedule**: Add scheduled trigger for catalog-builder to auto-refresh catalog (daily/hourly)
- [ ] **Lambda Layers**: Extract common dependencies into shared layers for faster deployments and smaller packages
- [ ] **DynamoDB Auto-Scaling**: Implement auto-scaling for tables based on usage patterns
- [ ] **EventBridge Integration**: Replace synchronous Lambda invocations with async EventBridge for better decoupling
- [ ] **Multi-Environment Support**: Add dev/staging/prod environments using Terraform workspaces

### Monitoring & Operations

- [ ] **CloudWatch Alarms**: Add alarms for Lambda errors, API Gateway failures, DynamoDB throttling with SNS notifications
- [ ] **X-Ray Tracing**: Enable distributed tracing for debugging cross-Lambda workflows
- [ ] **Log Retention Policy**: Standardize CloudWatch Logs retention across all functions (currently 7 days for API Gateway)
- [ ] **Operational Runbook**: Document common procedures (secret rotation, troubleshooting, catalog rebuild)

### Development & Maintenance

- [ ] **Terraform Validation**: Add pre-commit hooks for `terraform fmt`, `terraform validate`, `tflint`
- [ ] **Architecture Diagram**: Create visual diagram showing component interactions and data flows
- [ ] **Drift Detection**: Set up periodic drift detection to catch manual infrastructure changes
- [ ] **Cost Tagging**: Expand resource tags for better cost allocation tracking

## License

Proprietary - Tavern Labs
