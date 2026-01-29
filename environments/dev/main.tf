terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "keyvera-iam-infra"
    key    = "kratos-infra/dev/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# Common tags
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.app_name
    ManagedBy   = "Terraform"
  }
}

# CloudWatch Module
module "cloudwatch" {
  source = "../../modules/cloudwatch"

  app_name           = var.app_name
  environment        = var.environment
  log_retention_days = var.log_retention_days
  common_tags        = local.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security-groups"

  app_name                   = var.app_name
  environment                = var.environment
  vpc_id                     = var.vpc_id
  vpc_cidr                   = var.vpc_cidr
  public_port                = var.public_port
  admin_port                 = var.admin_port
  allowed_security_group_ids = var.allowed_security_group_ids
  common_tags                = local.common_tags
}

# S3 Module for Config Storage
module "s3" {
  source = "../../modules/s3"

  app_name        = var.app_name
  environment     = var.environment
  ecs_task_role_id = aws_iam_role.ecs_task.id
  common_tags     = local.common_tags
}

# ACM Module
module "acm" {
  source = "../../modules/acm"

  app_name       = var.app_name
  environment    = var.environment
  domain         = var.domain
  hosted_zone_id = var.hosted_zone_id
  common_tags    = local.common_tags
}

# Load Balancer Module (single ALB for public API only)
module "load_balancer" {
  source = "../../modules/alb"
  app_name              = var.app_name
  environment           = var.environment
  vpc_id                = var.vpc_id
  public_subnet_ids     = var.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_public_security_group_id
  certificate_arn       = module.acm.certificate_arn
  public_port           = var.public_port
  access_logs_enabled    = var.access_logs_enabled
  access_logs_bucket    = var.access_logs_bucket
  common_tags           = local.common_tags
}

# Route53 Module
module "route53" {
  source = "../../modules/route53"

  hosted_zone_id = var.hosted_zone_id
  domain         = var.domain
  alb_dns_name   = module.load_balancer.public_alb_dns_name
  alb_zone_id    = module.load_balancer.public_alb_zone_id
  common_tags    = local.common_tags
}

# ECS Module (public via ALB; admin via Service Discovery, SG-restricted)
module "ecs" {
  source = "../../modules/ecs"
  app_name                     = var.app_name
  environment                  = var.environment
  vpc_id                       = var.vpc_id
  subnet_ids                   = var.public_subnet_ids
  kratos_image                 = var.kratos_image
  kratos_image_tag             = var.kratos_image_tag
  public_port                  = var.public_port
  admin_port                   = var.admin_port
  cpu                          = var.cpu
  memory                       = var.memory
  desired_count                = var.desired_count
  ecs_tasks_security_group_id = module.security_groups.ecs_tasks_security_group_id
  public_target_group_arn     = module.load_balancer.public_target_group_arn
  kratos_log_group_name       = module.cloudwatch.kratos_log_group_name
  kratos_log_group_arn        = module.cloudwatch.kratos_log_group_arn
  aws_region                   = var.aws_region
  kratos_environment_vars       = var.kratos_environment_vars
  kratos_secrets               = var.kratos_secrets
  secrets_manager_secret_arns  = var.secrets_manager_secret_arns
  s3_config_bucket_name        = module.s3.bucket_name
  ecs_task_role_arn            = aws_iam_role.ecs_task.arn
  common_tags                  = local.common_tags
}
