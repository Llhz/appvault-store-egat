# AppVault Store — Azure Infrastructure (IaC)

Terraform configuration to deploy the AppVault Store application on **Azure Kubernetes Service (AKS)** with secrets managed by **Azure Key Vault**.

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                  Resource Group                       │
│                                                       │
│  ┌─────────┐   ┌──────────────┐   ┌──────────────┐  │
│  │  VNet   │   │     AKS      │   │  Key Vault   │  │
│  │         │◄──┤  (workload   │──►│  (RBAC mode) │  │
│  │ snet-aks│   │   identity)  │   │              │  │
│  └─────────┘   └──────┬───────┘   └──────────────┘  │
│                        │                              │
│                ┌───────┴────────┐                     │
│                │      ACR       │                     │
│                │  (AcrPull via  │                     │
│                │  kubelet MI)   │                     │
│                └────────────────┘                     │
└──────────────────────────────────────────────────────┘
```

### Resources Created

| Resource | Purpose |
|---|---|
| Resource Group | Container for all resources |
| Virtual Network + Subnet | Network isolation for AKS |
| AKS Cluster | Kubernetes runtime with workload identity & Key Vault CSI driver |
| Container Registry (ACR) | Private Docker image registry |
| Key Vault | Secrets storage (admin password, Spring profiles) |
| User Assigned Identity | Workload identity for pod-level Key Vault access |
| Federated Identity Credential | Links K8s service account to Azure identity |

### Security Features

- **Workload Identity** — pods authenticate to Key Vault using federated OIDC tokens (no stored credentials)
- **Key Vault CSI Driver** — secrets auto-synced to Kubernetes Secrets with rotation every 2 minutes
- **RBAC on Key Vault** — fine-grained Azure RBAC instead of access policies
- **AcrPull via Managed Identity** — no registry credentials needed in the cluster
- **Network Policy (Calico)** — network segmentation within the cluster
- **Autoscaling** — AKS node pool scales between min/max node counts

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.50
- An Azure subscription with Owner or Contributor + User Access Administrator

## Quick Start

```bash
cd iac-azure

# Login to Azure
az login

# Initialize Terraform
terraform init

# Plan (dev environment)
terraform plan -var-file=environments/dev.tfvars

# Apply
terraform apply -var-file=environments/dev.tfvars

# Get AKS credentials
az aks get-credentials \
  --resource-group "$(terraform output -raw resource_group_name)" \
  --name "$(terraform output -raw aks_cluster_name)"
```

## Environment Configs

| File | Description |
|---|---|
| `environments/dev.tfvars` | Development — small nodes, low scale |
| `environments/prod.tfvars` | Production — larger nodes, higher scale |

## GitHub Actions

### Required Repository Secrets

Configure these in **Settings → Secrets and variables → Actions**:

| Secret | Description |
|---|---|
| `AZURE_CLIENT_ID` | App registration client ID (for OIDC) |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target subscription ID |
| `ACR_NAME` | Container Registry name |
| `AKS_RESOURCE_GROUP` | Resource group containing AKS |
| `AKS_CLUSTER_NAME` | AKS cluster name |
| `KEY_VAULT_NAME` | Key Vault name |
| `WORKLOAD_IDENTITY_CLIENT_ID` | Managed identity client ID |

### Workflows

| Workflow | File | Trigger |
|---|---|---|
| **Infrastructure** | `.github/workflows/infra-terraform.yml` | Push/PR to `iac-azure/**` |
| **Deploy to AKS** | `.github/workflows/deploy-aks.yml` | Push to `src/**`, after infra |

#### Setting up OIDC for GitHub Actions

```bash
# Create app registration
az ad app create --display-name "github-actions-appvault"

# Create federated credential (replace values)
az ad app federated-credential create \
  --id <APP_OBJECT_ID> \
  --parameters '{
    "name": "github-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:<OWNER>/<REPO>:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

## Deploying the Application

After infrastructure is provisioned:

```bash
# Build & push image to ACR
ACR_SERVER=$(terraform output -raw acr_login_server)
az acr login --name $(terraform output -raw acr_name)

mvn compile jib:build -DskipTests \
  -Djib.to.image="${ACR_SERVER}/appvault/appvault-store" \
  -Djib.to.tags="latest"

# Substitute variables in K8s manifest
export ACR_LOGIN_SERVER="$ACR_SERVER"
export WORKLOAD_IDENTITY_CLIENT_ID=$(terraform output -raw app_workload_identity_client_id)
export KEY_VAULT_NAME=$(terraform output -raw key_vault_name)
export AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)

envsubst < k8s/app-deployment.yaml | kubectl apply -f -
```
