# Quick Start Guide

Deploy Ory Kratos on AWS in under 30 minutes. This guide assumes you have an AWS account, Terraform installed, and basic familiarity with AWS services.

## Prerequisites Checklist

- [ ] AWS Account with IAM permissions for ECS, ALB, S3, Route53, ACM, Secrets Manager
- [ ] Terraform >= 1.5.0
- [ ] AWS CLI configured (`aws configure`)
- [ ] Route53 hosted zone for your domain
- [ ] VPC with public subnets (or create default VPC)
- [ ] PostgreSQL instance (RDS or external)
- [ ] S3 bucket for Terraform state

## Step 1: Clone and Navigate

```bash
cd kratos-infra/environments/dev
```

## Step 2: Configure Terraform Backend

Create an S3 bucket for Terraform state (or use existing):

```bash
aws s3 mb s3://your-terraform-state-bucket --region us-east-1
```

Initialize Terraform:

```bash
terraform init \
  -backend-config="bucket=your-terraform-state-bucket" \
  -backend-config="key=kratos-infra/dev/terraform.tfstate" \
  -backend-config="region=us-east-1"
```

## Step 3: Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
vpc_id            = "vpc-xxxxxxxxx"
vpc_cidr          = "10.0.0.0/16"
public_subnet_ids = ["subnet-xxx", "subnet-yyy"]
hosted_zone_id    = "Z1234567890ABC"
domain            = "identity.your-domain.com"
```

## Step 4: Customize Kratos Config

Edit `../../config/kratos-config.yaml`:

- Replace `identity.example.com` with your domain (e.g., `identity.your-domain.com`)
- Replace `.example.com` with your cookie domain (e.g., `.your-domain.com`)
- Update CORS origins, return URLs, and WebAuthn origins as needed

## Step 5: Configure Secrets

Create an AWS Secrets Manager secret with your Kratos secrets:

```bash
aws secretsmanager create-secret \
  --name dev/kratos \
  --secret-string '{
    "DSN": "postgres://user:pass@host:5432/kratos_db?sslmode=require",
    "SECRETS_COOKIE": "your-cookie-secret-32-chars-minimum",
    "SECRETS_CIPHER": "your-cipher-secret-32-chars-minimum",
    "COURIER_SMTP_CONNECTION_URI": "smtps://user:pass@smtp.example.com:587/?skip_ssl_verify=false"
  }'
```

Update `terraform.tfvars` with the secret ARN (get from AWS Console or CLI):

```hcl
secrets_manager_secret_arns = [
  "arn:aws:secretsmanager:us-east-1:YOUR_ACCOUNT_ID:secret:dev/kratos*"
]

kratos_secrets = [
  { name = "DSN", valueFrom = "arn:aws:secretsmanager:REGION:ACCOUNT:secret:dev/kratos-xxxxxx:DSN::" },
  { name = "SECRETS_COOKIE", valueFrom = "arn:aws:secretsmanager:REGION:ACCOUNT:secret:dev/kratos-xxxxxx:SECRETS_COOKIE::" },
  { name = "SECRETS_CIPHER", valueFrom = "arn:aws:secretsmanager:REGION:ACCOUNT:secret:dev/kratos-xxxxxx:SECRETS_CIPHER::" },
  { name = "COURIER_SMTP_CONNECTION_URI", valueFrom = "arn:aws:secretsmanager:REGION:ACCOUNT:secret:dev/kratos-xxxxxx:COURIER_SMTP_CONNECTION_URI::" }
]

kratos_environment_vars = [
  { name = "COURIER_SMTP_FROM_ADDRESS", value = "noreply@your-domain.com" },
  { name = "SERVE_PUBLIC_CORS_ALLOWED_ORIGINS_0", value = "https://app.your-domain.com" },
  { name = "SELFSERVICE_ALLOWED_RETURN_URLS_0", value = "https://identity.your-domain.com/" },
  { name = "SELFSERVICE_METHODS_WEBAUTHN_CONFIG_RP_ORIGINS_0", value = "https://identity.your-domain.com" }
]
```

## Step 6: Deploy Infrastructure

```bash
terraform plan
terraform apply
```

This creates: ECS cluster, ALB, security groups, S3 bucket, ACM certificate, Route53 record, CloudWatch log groups.

## Step 7: Upload Config to S3

```bash
BUCKET_NAME=$(terraform output -raw s3_config_bucket_name)
cd ../..
./scripts/upload-config-to-s3.sh "$BUCKET_NAME" ./config
```

## Step 8: Verify Deployment

```bash
cd environments/dev

# Health check (replace with your domain)
curl https://identity.your-domain.com/health/ready

# ECS service status
aws ecs describe-services \
  --cluster $(terraform output -raw ecs_cluster_id) \
  --services kratos-dev-kratos

# View logs
aws logs tail $(terraform output -raw kratos_log_group_name) --follow
```

## Migrations

Database migrations run automatically as an init container when each Kratos task starts. No manual migration step required.

## Troubleshooting

### ECS Tasks Not Starting

1. Check CloudWatch logs for errors
2. Verify Secrets Manager ARNs and IAM permissions
3. Confirm S3 config files exist
4. Check security group rules

### Config File Not Found

1. Run `./scripts/upload-config-to-s3.sh $BUCKET_NAME ./config`
2. Verify files: `aws s3 ls s3://$BUCKET_NAME/`
3. Restart ECS service to trigger new task

### Health Check Fails

1. Ensure DNS has propagated (may take a few minutes)
2. Check ALB target group health
3. Verify Kratos is listening on port 4433

## Next Steps

- [CONFIGURATION.md](./CONFIGURATION.md) - Full configuration reference
- Set up CI/CD with GitHub Actions
- Configure monitoring and alerts
