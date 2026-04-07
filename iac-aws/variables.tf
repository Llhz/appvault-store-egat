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

variable "region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (EKS nodes)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (load balancers)"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

# -----------------------------------------------------------------------------
# EKS
# -----------------------------------------------------------------------------
variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.30"
}

variable "eks_node_instance_types" {
  description = "Instance types for the EKS managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_desired_size" {
  description = "Desired number of nodes in the default node group"
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Minimum number of nodes for autoscaling"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximum number of nodes for autoscaling"
  type        = number
  default     = 5
}

# -----------------------------------------------------------------------------
# Secrets Manager (sensitive — provide via TF_VAR_ env vars or .tfvars)
# -----------------------------------------------------------------------------
variable "app_admin_email" {
  description = "Admin email for the application"
  type        = string
  default     = "admin@appvault.com"
}

variable "app_admin_password" {
  description = "Admin password for the application (stored in Secrets Manager)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "app_spring_profiles" {
  description = "Spring profiles to activate"
  type        = string
  default     = "prod"
}
