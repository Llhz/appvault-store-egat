# -----------------------------------------------------------------------------
# General
# -----------------------------------------------------------------------------
variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
  default     = "appvault"
}

variable "environment" {
  description = "Environment name (dev, stg, uat, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "stg", "uat", "prod"], var.environment)
    error_message = "Environment must be one of: dev, stg, uat, prod."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "southeastasia"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------
variable "vnet_address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_prefix" {
  description = "Address prefix for the AKS subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# -----------------------------------------------------------------------------
# AKS
# -----------------------------------------------------------------------------
variable "kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.30"
}

variable "aks_default_node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "aks_default_node_vm_size" {
  description = "VM size for the default node pool"
  type        = string
  default     = "Standard_B2s"
}

variable "aks_default_node_min_count" {
  description = "Minimum node count for autoscaling"
  type        = number
  default     = 1
}

variable "aks_default_node_max_count" {
  description = "Maximum node count for autoscaling"
  type        = number
  default     = 5
}

# -----------------------------------------------------------------------------
# Key Vault secrets (sensitive — provide via TF_VAR_ env vars or .tfvars)
# -----------------------------------------------------------------------------
variable "app_admin_email" {
  description = "Admin email for the application"
  type        = string
  default     = "admin@appvault.com"
}

variable "app_admin_password" {
  description = "Admin password for the application (stored in Key Vault)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "app_spring_profiles" {
  description = "Spring profiles to activate"
  type        = string
  default     = "prod"
}
