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

# Common tags and derived values
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.app_name
    ManagedBy   = "Terraform"
  }
  # Route53 record names (subdomains): identity.oauthentra.com -> "identity", auth.oauthentra.com -> "auth"
  kratos_record_name = split(".", var.kratos_domain)[0]
  hydra_record_name = split(".", var.hydra_domain)[0]
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

  app_name                    = var.app_name
  environment                 = var.environment
  vpc_id                      = var.vpc_id
  vpc_cidr                    = var.vpc_cidr
  kratos_public_port          = var.kratos_public_port
  kratos_admin_port           = var.kratos_admin_port
  hydra_public_port           = var.hydra_public_port
  hydra_admin_port            = var.hydra_admin_port
  allowed_security_group_ids  = var.allowed_security_group_ids
  common_tags                 = local.common_tags
}

# S3 Module for Config Storage (shared bucket for Kratos + Hydra)
module "s3" {
  source = "../../modules/s3"

  app_name                 = var.app_name
  environment              = var.environment
  kratos_ecs_task_role_id = aws_iam_role.ecs_task.id
  hydra_ecs_task_role_id  = aws_iam_role.ecs_task_hydra.id
  common_tags              = local.common_tags
}

# ACM Module (identity + auth subdomains)
module "acm" {
  source = "../../modules/acm"

  app_name                  = var.app_name
  environment               = var.environment
  domain                    = var.kratos_domain
  hosted_zone_id            = var.hosted_zone_id
  subject_alternative_names = var.acm_subject_alternative_names
  common_tags               = local.common_tags
}

# Load Balancer Module (shared ALB with host-based routing)
module "load_balancer" {
  source = "../../modules/alb"
  app_name              = var.app_name
  environment           = var.environment
  vpc_id                = var.vpc_id
  public_subnet_ids     = var.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_public_security_group_id
  certificate_arn       = module.acm.certificate_arn
  kratos_public_port    = var.kratos_public_port
  kratos_host           = var.kratos_domain
  hydra_public_port     = var.hydra_public_port
  hydra_host            = var.hydra_domain
  access_logs_enabled   = var.access_logs_enabled
  access_logs_bucket    = var.access_logs_bucket
  common_tags           = local.common_tags
}

# Route53 Module (Kratos + Hydra)
module "route53" {
  source = "../../modules/route53"

  hosted_zone_id      = var.hosted_zone_id
  kratos_record_name  = local.kratos_record_name
  alb_dns_name        = module.load_balancer.public_alb_dns_name
  alb_zone_id         = module.load_balancer.public_alb_zone_id
  hydra_record_name   = local.hydra_record_name
  common_tags         = local.common_tags
}

# Kratos ECS Module (public via ALB; admin via Service Discovery)
module "ecs" {
  source = "../../modules/ecs"

  app_name                          = var.app_name
  environment                       = var.environment
  vpc_id                            = var.vpc_id
  subnet_ids                        = var.public_subnet_ids
  kratos_image                      = var.kratos_image
  kratos_image_tag                  = var.kratos_image_tag
  kratos_public_port                = var.kratos_public_port
  kratos_admin_port                 = var.kratos_admin_port
  kratos_cpu                        = var.kratos_cpu
  kratos_memory                     = var.kratos_memory
  kratos_desired_count              = var.kratos_desired_count
  kratos_ecs_tasks_security_group_id = module.security_groups.kratos_ecs_tasks_security_group_id
  kratos_target_group_arn           = module.load_balancer.kratos_target_group_arn
  kratos_log_group_name             = module.cloudwatch.kratos_log_group_name
  kratos_log_group_arn              = module.cloudwatch.kratos_log_group_arn
  aws_region                        = var.aws_region
  kratos_environment_vars           = var.kratos_environment_vars
  kratos_secrets                    = var.kratos_secrets
  kratos_secrets_manager_secret_arns = var.kratos_secrets_manager_secret_arns
  kratos_s3_config_bucket_name      = module.s3.bucket_name
  kratos_ecs_task_role_arn          = aws_iam_role.ecs_task.arn
  common_tags                       = local.common_tags
}

# Security Groups (pass Hydra ports for Hydra ECS SG)
# Note: security_groups module is called above with public_port/admin_port for Kratos.
# Hydra ports are passed via variables with defaults.

# Hydra ECS Module (public via ALB auth.oauthentra.com; admin via Service Discovery)
module "hydra_ecs" {
  source = "../../modules/hydra-ecs"

  app_name                          = var.app_name
  environment                       = var.environment
  vpc_id                            = var.vpc_id
  subnet_ids                        = var.public_subnet_ids
  hydra_image                       = var.hydra_image
  hydra_image_tag                   = var.hydra_image_tag
  hydra_public_port                 = var.hydra_public_port
  hydra_admin_port                  = var.hydra_admin_port
  hydra_cpu                         = var.hydra_cpu
  hydra_memory                      = var.hydra_memory
  hydra_desired_count               = var.hydra_desired_count
  hydra_ecs_tasks_security_group_id = module.security_groups.hydra_ecs_tasks_security_group_id
  hydra_target_group_arn            = module.load_balancer.hydra_target_group_arn
  hydra_log_group_name              = module.cloudwatch.hydra_log_group_name
  hydra_log_group_arn               = module.cloudwatch.hydra_log_group_arn
  aws_region                        = var.aws_region
  hydra_environment_vars            = var.hydra_environment_vars
  hydra_secrets                     = var.hydra_secrets
  hydra_secrets_manager_secret_arns = var.hydra_secrets_manager_secret_arns
  hydra_s3_config_bucket_name       = module.s3.bucket_name
  hydra_s3_config_key               = var.hydra_s3_config_key
  hydra_ecs_task_role_arn           = aws_iam_role.ecs_task_hydra.arn
  common_tags                       = local.common_tags
}
