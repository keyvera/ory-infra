output "bucket_name" {
  description = "S3 bucket name for Kratos config"
  value       = aws_s3_bucket.kratos_config.id
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.kratos_config.arn
}
