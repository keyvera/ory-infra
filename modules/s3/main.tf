# S3 Bucket for Kratos Configuration Files
resource "aws_s3_bucket" "kratos_config" {
  bucket = "${var.app_name}-${var.environment}-kratos-config"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-${var.environment}-kratos-config"
    }
  )
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "kratos_config" {
  bucket = aws_s3_bucket.kratos_config.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "kratos_config" {
  bucket = aws_s3_bucket.kratos_config.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "kratos_config" {
  bucket = aws_s3_bucket.kratos_config.id

  block_public_acls       = true
  block_public_policy      = true
  ignore_public_acls       = true
  restrict_public_buckets  = true
}

# S3 Bucket Lifecycle Configuration
# resource "aws_s3_bucket_lifecycle_configuration" "kratos_config" {
#   bucket = aws_s3_bucket.kratos_config.id

#   rule {
#     id     = "delete-old-versions"
#     status = "Enabled"

#     noncurrent_version_expiration {
#       noncurrent_days = var.environment == "prod" ? 16 : 7
#     }
#   }
# }

# IAM Policy for Kratos ECS Task to Read from S3
resource "aws_iam_role_policy" "kratos_ecs_task_s3_read" {
  name = "${var.app_name}-${var.environment}-kratos-s3-config-read"
  role = var.kratos_ecs_task_role_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${aws_s3_bucket.kratos_config.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.kratos_config.arn
      }
    ]
  })
}

# IAM Policy for Hydra ECS Task to Read from S3
resource "aws_iam_role_policy" "hydra_ecs_task_s3_read" {
  name = "${var.app_name}-${var.environment}-hydra-s3-config-read"
  role = var.hydra_ecs_task_role_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${aws_s3_bucket.kratos_config.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.kratos_config.arn
      }
    ]
  })
}
