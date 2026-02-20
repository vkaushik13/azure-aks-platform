resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "system"
    node_count          = var.system_node_count
    vm_size             = var.system_vm_size
    availability_zones  = var.availability_zones
    os_disk_size_gb     = 128
    type                = "VirtualMachineScaleSets"
    vnet_subnet_id      = var.subnet_id
    enable_auto_scaling = true
    min_count           = var.system_min_count
    max_count           = var.system_max_count

    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.environment
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.managed_identity_id]
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "calico"
    load_balancer_sku  = "standard"
    outbound_type      = "userDefinedRouting"
    service_cidr       = var.service_cidr
    dns_service_ip     = var.dns_service_ip
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_ids
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  microsoft_defender {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  api_server_access_profile {
    authorized_ip_ranges = var.api_server_authorized_ip_ranges
  }

  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [1, 2]
    }
  }

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  for_each = var.user_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = each.value.vm_size
  node_count            = each.value.node_count
  availability_zones    = var.availability_zones
  vnet_subnet_id        = var.subnet_id
  enable_auto_scaling   = true
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  os_disk_size_gb       = each.value.os_disk_size_gb

  node_labels = merge(
    {
      "nodepool-type" = "user"
      "environment"   = var.environment
      "workload"      = each.key
    },
    each.value.node_labels
  )

  node_taints = each.value.node_taints
  tags        = var.tags
}
