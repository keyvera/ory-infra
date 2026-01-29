# Configuration Guide

## Kratos Configuration

Kratos configuration is stored in S3 and downloaded to containers at startup via an init container. The config is mounted at `/etc/config/kratos/`.

### Environment Variables

Ory Kratos maps YAML config keys to environment variables: nested keys become `UPPER_SNAKE_CASE` (e.g. `courier.smtp.connection_uri` → `COURIER_SMTP_CONNECTION_URI`). Arrays use `_0`, `_1`, etc. See [Ory Configuring](https://www.ory.sh/docs/ecosystem/configuring).

**Required (use AWS Secrets Manager / valueFrom in ECS for sensitive values):**

- `DSN` - PostgreSQL connection string
- `SECRETS_COOKIE` - Comma-separated cookie secrets (32+ chars each)
- `SECRETS_CIPHER` - Comma-separated cipher secrets (32+ chars each)

**Courier (email):**

- `COURIER_SMTP_CONNECTION_URI` - SMTP URI (store in Secrets Manager)
- `COURIER_SMTP_FROM_ADDRESS` - From address (e.g., `noreply@your-domain.com`)

**Optional (override config file):**

- `SERVE_PUBLIC_CORS_ALLOWED_ORIGINS_0`, `_1`, ... - CORS allowed origins
- `SELFSERVICE_ALLOWED_RETURN_URLS_0`, `_1`, ... - Allowed return URLs
- `SELFSERVICE_METHODS_WEBAUTHN_CONFIG_RP_ORIGINS_0`, `_1`, ... - WebAuthn RP origins

### Config File Customization

Before deployment, edit `config/kratos-config.yaml` and replace placeholders:

- `identity.example.com` → Your Kratos public domain
- `.example.com` → Your cookie domain (e.g., `.your-domain.com`)
- `Your Identity Service` → Your display name

### Updating Configuration

1. Edit files in `config/` directory
2. Upload to S3: `./scripts/upload-config-to-s3.sh $BUCKET_NAME ./config`
3. Restart ECS service to pick up changes (or wait for next deployment)

## Hydra Configuration

Hydra config is stored at `config/hydra-config.yaml` and uploaded to S3 with key `hydra-config.yaml` (same bucket as Kratos, different key).

### Required Hydra Secrets (Secrets Manager)

- `DSN` - PostgreSQL connection string (can share DB with Kratos or use separate database)

### Hydra Environment Variables (optional overrides)

- `URLS_SELF_ISSUER` - OAuth2 issuer URL (e.g., https://auth.oauthentra.com/)
- `URLS_CONSENT`, `URLS_LOGIN`, `URLS_LOGOUT`, etc. - Override URLs in config

### Upload Hydra Config

The same upload script uploads both Kratos and Hydra config:

```bash
./scripts/upload-config-to-s3.sh "$BUCKET_NAME" ./config
```

This uploads `kratos-config.yaml`, `identity.schema.json`, and `hydra-config.yaml`.

## Required Secrets

### Cookie Secrets

```bash
openssl rand -hex 32
```

Set multiple for rotation: `SECRETS_COOKIE="secret1,secret2,secret3"`

### Cipher Secrets

```bash
openssl rand -hex 32
```

Set multiple: `SECRETS_CIPHER="secret1,secret2,secret3"`

## Database Connection

DSN format: `postgres://username:password@host:5432/database?sslmode=require`

Store in AWS Secrets Manager and reference via `valueFrom` in `kratos_secrets`.

## CORS Configuration

Set via environment variables or update `allowed_origins` in `kratos-config.yaml`:

```yaml
cors:
  enabled: true
  allowed_origins:
    - "https://app.your-domain.com"
    - "https://admin.your-domain.com"
```

## Security Best Practices

1. **Never commit secrets** to version control
2. **Use AWS Secrets Manager** for DSN, cookie/cipher secrets, SMTP credentials
3. **Rotate secrets regularly** (SECRETS_COOKIE, SECRETS_CIPHER)
4. **Use SSL/TLS** for database connections (`sslmode=require`)
5. **Restrict admin endpoint** to VPC only (already configured)

## Troubleshooting

### Config File Not Found

- Verify S3 bucket contains `kratos-config.yaml` and `identity.schema.json`
- Check init container logs in CloudWatch
- Verify ECS task role has S3 read permissions

### Invalid Configuration

- Validate YAML syntax
- Check Kratos logs for specific errors
- Ensure environment variable names match Kratos expectations
