resource "azurerm_kubernetes_cluster" "aks" {
  name                = local.aks_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${local.aks_name}-dns"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Free"
  node_resource_group = local.node_rg_name

  local_account_disabled            = false
  role_based_access_control_enabled = true

  default_node_pool {
    name                 = "agentpool"
    node_count           = 2
    vm_size              = "Standard_D2as_v5"
    os_sku               = "Ubuntu"
    vnet_subnet_id       = azurerm_subnet.aks_subnet.id
    auto_scaling_enabled = true # FIXED: Modernized argument for v4.x
    min_count            = 2
    max_count            = 2
    zones                = []
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "azure"
    pod_cidr            = "192.168.0.0/16"
  }

  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.agw.id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "aks_kv_secrets" {
  principal_id                     = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].object_id
  role_definition_name             = "Key Vault Secrets User"
  scope                            = azurerm_key_vault.kv.id
  skip_service_principal_aad_check = true
}


data "azurerm_user_assigned_identity" "agic" {
  name                = "ingressapplicationgateway-${azurerm_kubernetes_cluster.aks.name}"
  resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group
}

resource "azurerm_role_assignment" "agic_agw_contributor" {
  principal_id         = data.azurerm_user_assigned_identity.agic.principal_id
  role_definition_name = "Contributor"
  scope                = azurerm_application_gateway.agw.id
}

# AGIC must be able to join the AGW's subnet (Microsoft.Network/virtualNetworks/subnets/join/action)
# to attach the gateway IP configuration. Without this, AppGateway CreateOrUpdate fails with
# ApplicationGatewayInsufficientPermissionOnSubnet and no backend pool/config is ever pushed.
resource "azurerm_role_assignment" "agic_agw_subnet_join" {
  principal_id         = data.azurerm_user_assigned_identity.agic.principal_id
  role_definition_name = "Network Contributor"
  scope                = azurerm_subnet.agw_subnet.id
}

resource "azurerm_role_assignment" "agic_rg_reader" {
  principal_id         = data.azurerm_user_assigned_identity.agic.principal_id
  role_definition_name = "Reader"
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
}