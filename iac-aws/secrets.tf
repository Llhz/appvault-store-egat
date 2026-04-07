# -----------------------------------------------------------------------------
# Data: current AWS caller identity & region
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# AWS Secrets Manager — Comparable to Azure Key Vault
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "admin_password" {
  name                    = "${local.name_prefix}/app-admin-password"
  description             = "AppVault admin password"
  recovery_window_in_days = var.environment == "prod" ? 30 : 0

  tags = {
    Name = "${local.name_prefix}-admin-password"
  }
}

resource "aws_secretsmanager_secret_version" "admin_password" {
  secret_id     = aws_secretsmanager_secret.admin_password.id
  secret_string = var.app_admin_password != "" ? var.app_admin_password : "ChangeMe123!"
}

resource "aws_secretsmanager_secret" "spring_profiles" {
  name                    = "${local.name_prefix}/app-spring-profiles"
  description             = "AppVault Spring profiles"
  recovery_window_in_days = var.environment == "prod" ? 30 : 0

  tags = {
    Name = "${local.name_prefix}-spring-profiles"
  }
}

resource "aws_secretsmanager_secret_version" "spring_profiles" {
  secret_id     = aws_secretsmanager_secret.spring_profiles.id
  secret_string = var.app_spring_profiles
}

# -----------------------------------------------------------------------------
# IAM Role for app pods (IRSA) — Comparable to Azure Workload Identity
# Allows EKS pods in the appvault namespace to read secrets
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "app_secrets_read" {
  name        = "${local.name_prefix}-secrets-read"
  description = "Allow reading AppVault secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.admin_password.arn,
          aws_secretsmanager_secret.spring_profiles.arn
        ]
      }
    ]
  })
}

module "app_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${local.name_prefix}-app-irsa"

  role_policy_arns = {
    secrets_read = aws_iam_policy.app_secrets_read.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["appvault:appvault-store"]
    }
  }
}

# -----------------------------------------------------------------------------
# Secrets Store CSI Driver IRSA — For mounting secrets into pods
# -----------------------------------------------------------------------------
module "secrets_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${local.name_prefix}-secrets-csi"

  role_policy_arns = {
    secrets_read = aws_iam_policy.app_secrets_read.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["appvault:secrets-store-csi-driver"]
    }
  }
}
