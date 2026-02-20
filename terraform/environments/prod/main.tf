terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-prod"
    storage_account_name = "stterraformstateprod"
    container_name       = "tfstate"
    key                  = "aks-platform/prod/terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

locals {
  environment = "prod"
  location    = "australiaeast"
  tags = {
    environment = "prod"
    managed-by  = "terraform"
    team        = "platform-engineering"
    cost-center = "platform"
  }
}

module "networking" {
  source              = "../../modules/networking"
  vnet_name           = "vnet-aks-prod"
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  vnet_address_space  = ["10.0.0.0/8"]
  aks_subnet_cidr     = ["10.1.0.0/16"]
  pe_subnet_cidr      = ["10.2.0.0/24"]
  environment         = local.environment
  tags                = local.tags
}

module "security" {
  source              = "../../modules/security"
  key_vault_name      = "kv-aks-platform-prod"
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  resource_group_id   = azurerm_resource_group.main.id
  acr_name            = "craksplatformprod"
  aks_subnet_id       = module.networking.aks_subnet_id
  pe_subnet_id        = module.networking.pe_subnet_id
  environment         = local.environment
  tags                = local.tags
}

module "monitoring" {
  source                   = "../../modules/monitoring"
  workspace_name           = "law-aks-platform-prod"
  location                 = local.location
  resource_group_name      = azurerm_resource_group.main.name
  log_retention_days       = 90
  environment              = local.environment
  tags                     = local.tags
}

module "aks" {
  source                          = "../../modules/aks-cluster"
  cluster_name                    = "aks-platform-prod"
  location                        = local.location
  resource_group_name             = azurerm_resource_group.main.name
  dns_prefix                      = "aks-platform-prod"
  kubernetes_version              = "1.29"
  environment                     = local.environment
  system_node_count               = 5
  system_vm_size                  = "Standard_D16s_v3"
  system_min_count                = 3
  system_max_count                = 10
  availability_zones              = ["1", "2", "3"]
  subnet_id                       = module.networking.aks_subnet_id
  managed_identity_id             = azurerm_user_assigned_identity.aks.id
  log_analytics_workspace_id      = module.monitoring.workspace_id
  admin_group_ids                 = var.admin_group_ids
  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges

  user_node_pools = {
    workload = {
      vm_size         = "Standard_D8s_v3"
      node_count      = 5
      min_count       = 3
      max_count       = 20
      os_disk_size_gb = 256
      node_labels     = { "workload-type" = "general" }
      node_taints     = []
    }
    gpu = {
      vm_size         = "Standard_NC6s_v3"
      node_count      = 2
      min_count       = 0
      max_count       = 5
      os_disk_size_gb = 256
      node_labels     = { "workload-type" = "gpu" }
      node_taints     = ["nvidia.com/gpu=present:NoSchedule"]
    }
  }

  tags = local.tags
}

resource "azurerm_resource_group" "main" {
  name     = "rg-aks-platform-prod"
  location = local.location
  tags     = local.tags
}

resource "azurerm_user_assigned_identity" "aks" {
  name                = "mi-aks-platform-prod"
  location            = local.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}
