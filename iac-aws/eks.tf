# -----------------------------------------------------------------------------
# Amazon EKS — using terraform-aws-modules/eks/aws v21.15.1
# Comparable to Azure AKS with workload identity + Key Vault CSI
# -----------------------------------------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.15"

  cluster_name    = local.name_prefix
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Public endpoint for kubectl; private endpoint for node communication
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # Enable IRSA (IAM Roles for Service Accounts) — comparable to Azure Workload Identity
  enable_irsa = true

  # EKS Addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  # Managed node group — comparable to AKS default node pool with autoscaling
  eks_managed_node_groups = {
    default = {
      name           = "default"
      instance_types = var.eks_node_instance_types
      desired_size   = var.eks_node_desired_size
      min_size       = var.eks_node_min_size
      max_size       = var.eks_node_max_size

      disk_size = 30

      labels = {
        role = "general"
      }
    }
  }

  # Allow current caller and GitHub Actions OIDC to manage cluster
  enable_cluster_creator_admin_permissions = true
}
