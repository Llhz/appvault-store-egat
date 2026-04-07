# -----------------------------------------------------------------------------
# Data: current Azure client (for Key Vault access policies)
# -----------------------------------------------------------------------------
data "azurerm_client_config" "current" {}

# -----------------------------------------------------------------------------
# Azure Key Vault
# -----------------------------------------------------------------------------
resource "azurerm_key_vault" "main" {
  name                       = "kv-${local.name_prefix}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = true
  enable_rbac_authorization  = true
  tags                       = local.common_tags
}

# Grant the Terraform executor "Key Vault Secrets Officer" so it can manage secrets
resource "azurerm_role_assignment" "kv_terraform_secrets_officer" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Key Vault Secrets Officer"
  scope                = azurerm_key_vault.main.id
}

# -----------------------------------------------------------------------------
# Workload identity for the app to read Key Vault secrets
# -----------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "app_workload" {
  name                = "id-${local.name_prefix}-app"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_federated_identity_credential" "app_workload" {
  name                = "fed-${local.name_prefix}-app"
  resource_group_name = azurerm_resource_group.main.name
  parent_id           = azurerm_user_assigned_identity.app_workload.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject             = "system:serviceaccount:appvault:appvault-store"
}

# Grant workload identity "Key Vault Secrets User" on the vault
resource "azurerm_role_assignment" "kv_app_secrets_user" {
  principal_id                     = azurerm_user_assigned_identity.app_workload.principal_id
  role_definition_name             = "Key Vault Secrets User"
  scope                            = azurerm_key_vault.main.id
  skip_service_principal_aad_check = true
}

# -----------------------------------------------------------------------------
# Seed application secrets into Key Vault
# -----------------------------------------------------------------------------
resource "azurerm_key_vault_secret" "admin_password" {
  name         = "app-admin-password"
  value        = var.app_admin_password != "" ? var.app_admin_password : "ChangeMe123!"
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.kv_terraform_secrets_officer]
}

resource "azurerm_key_vault_secret" "spring_profiles" {
  name         = "app-spring-profiles"
  value        = var.app_spring_profiles
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.kv_terraform_secrets_officer]
}
