# Ory Kratos Self-Hosted Infrastructure on AWS

Production-grade Terraform infrastructure for deploying [Ory Kratos](https://www.ory.sh/kratos/) identity management on AWS using ECS Fargate. This repository provides a quick-start, open-source solution for self-hosting Kratos with minimal configuration.

## Architecture

- **Public Endpoint**: `https://identity.<your-domain>` - Internet-accessible via Application Load Balancer
- **Admin Endpoint**: Internal ALB accessible only within AWS VPC (traffic restricted by security groups)
- **Compute**: ECS Fargate service running Kratos container serving both public (4433) and admin (4434) APIs
- **Database**: PostgreSQL (connection string provided via AWS Secrets Manager)
- **Configuration Storage**: S3 bucket for Kratos config files (downloaded at startup via init container)
- **Networking**: Public and private subnets, security groups for isolation

## Prerequisites

- AWS Account with appropriate IAM permissions
- Terraform >= 1.5.0
- AWS CLI configured
- Route53 hosted zone for your domain
- VPC with public subnets
- PostgreSQL instance (RDS or self-managed)
- S3 bucket for Terraform state

## Project Structure

```
kratos-infra/
├── config/                    # Kratos configuration files (customize before deploy)
│   ├── kratos-config.yaml     # Production Kratos config - replace placeholders
│   └── identity.schema.json   # Identity schema definition
├── modules/                   # Reusable Terraform modules
│   ├── acm/                   # SSL certificate management
│   ├── alb/                   # Application Load Balancer
│   ├── cloudwatch/            # CloudWatch log groups
│   ├── ecs/                   # ECS cluster, services, task definitions
│   ├── s3/                    # S3 bucket for config storage
│   ├── route53/               # Route53 DNS records
│   └── security-groups/        # Security groups
├── environments/
│   ├── dev/                   # Development environment
│   └── prod/                  # Production environment
├── scripts/
│   └── upload-config-to-s3.sh # Upload config files to S3
└── .github/workflows/         # GitHub Actions CI/CD (optional)
```

## Quick Start

See [QUICKSTART.md](./QUICKSTART.md) for step-by-step deployment instructions.

## Configuration

### Required Variables

| Variable | Description |
|----------|-------------|
| `vpc_id` | VPC ID for deployment |
| `vpc_cidr` | VPC CIDR block |
| `public_subnet_ids` | Public subnet IDs for ALB and ECS |
| `hosted_zone_id` | Route53 hosted zone ID |
| `domain` | Domain for public endpoint (e.g., `identity.example.com`) |

### Secrets Management

**Never commit secrets.** Use AWS Secrets Manager for sensitive values:

1. **`secrets_manager_secret_arns`** - IAM permission for ECS task execution role:
   ```hcl
   secrets_manager_secret_arns = [
     "arn:aws:secretsmanager:REGION:ACCOUNT_ID:secret:ENV/kratos*"
   ]
   ```

2. **`kratos_secrets`** - Container secret injection via `valueFrom`:
   ```hcl
   kratos_secrets = [
     {
       name      = "DSN"
       valueFrom = "arn:aws:secretsmanager:REGION:ACCOUNT:secret:name-xxxxxx:DSN::"
     }
   ]
   ```

See [CONFIGURATION.md](./CONFIGURATION.md) for full configuration details.

## Deployment

### 1. Configure Terraform Backend

```bash
cd environments/dev
terraform init -backend-config="bucket=YOUR_STATE_BUCKET" \
               -backend-config="key=kratos-infra/dev/terraform.tfstate" \
               -backend-config="region=us-east-1"
```

### 2. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 3. Customize Kratos Config

Edit `config/kratos-config.yaml` and replace `identity.example.com` with your domain. Update CORS, return URLs, and WebAuthn origins as needed.

### 4. Plan and Apply

```bash
terraform plan
terraform apply
```

### 5. Upload Config to S3

```bash
BUCKET_NAME=$(terraform output -raw s3_config_bucket_name)
./scripts/upload-config-to-s3.sh "$BUCKET_NAME" ./config
```

## CI/CD (GitHub Actions)

The workflow uses GitHub Secrets for sensitive data. Required secrets:

- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- `TERRAFORM_STATE_BUCKET`
- `KRATOS_ENV_VARS_DEV` / `KRATOS_ENV_VARS_PROD` - JSON array of non-secret env vars
- `KRATOS_SECRETS_DEV` / `KRATOS_SECRETS_PROD` - JSON array of secret references

## Security

- **No hardcoded secrets** - All sensitive values from AWS Secrets Manager
- **Admin endpoint** - VPC-only, restricted by security groups
- **Encryption** - TLS for ALB, S3 server-side encryption
- **Least privilege** - Security groups and IAM policies follow least privilege

## Monitoring

- CloudWatch Logs for container output
- ECS Container Insights enabled
- ALB health checks on `/health/ready`

## Troubleshooting

```bash
# Check ECS service status
aws ecs describe-services --cluster <cluster-id> --services <service-name>

# View logs
aws logs tail /ecs/<log-group-name> --follow

# Verify S3 config
aws s3 ls s3://$BUCKET_NAME/
```

## License

Apache 2.0 - See [LICENSE](../LICENSE) for details.
