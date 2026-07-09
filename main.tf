data "azurerm_client_config" "current" {}

resource "azurerm_virtual_network" "vnet" {
  name                = local.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/8"]
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = local.aks_subnet
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.240.0.0/16"]
}

resource "azurerm_subnet" "agw_subnet" {
  name                 = local.agw_subnet
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.2.0.0/24"]
}

resource "azurerm_public_ip" "agw_pip" {
  name                = local.pip_name
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "agw" {
  name                = local.agw_name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  # Enforce modern TLS Policy to resolve 400 Deprecated TLS Error
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.agw_subnet.id
  }

  frontend_port {
    name = "frontend-port-80"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.agw_pip.id
  }

  backend_address_pool {
    name = "default-beap"
  }

  backend_http_settings {
    name                  = "default-be-htst"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
  }

  http_listener {
    name                           = "default-httplstn"
    frontend_ip_configuration_name = "frontend-ip-config"
    frontend_port_name             = "frontend-port-80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "default-rqrt"
    rule_type                  = "Basic"
    http_listener_name         = "default-httplstn"
    backend_address_pool_name  = "default-beap"
    backend_http_settings_name = "default-be-htst"
    priority                   = 100
  }
}

resource "azurerm_container_registry" "acr" {
  name                = local.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_key_vault" "kv" {
  name                       = local.kv_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
}

# The vault is RBAC-authorized (no access policies), so the identity running
# Terraform also needs an explicit role assignment to manage secrets - without
# this, azurerm_key_vault_secret gets a 403 ForbiddenByRbac on GetSecret/SetSecret.
resource "azurerm_role_assignment" "kv_secrets_officer_caller" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Key Vault Secrets Officer"
  scope                = azurerm_key_vault.kv.id
}

# Azure RBAC role assignments can take up to a couple of minutes to propagate;
# without waiting, the very first apply can hit a 403 ForbiddenByRbac on the secret below.
resource "time_sleep" "kv_rbac_propagation" {
  depends_on      = [azurerm_role_assignment.kv_secrets_officer_caller]
  create_duration = "60s"
}

resource "azurerm_key_vault_secret" "database_password" {
  name         = "DatabasePassword"
  value        = var.mysql_root_password
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [time_sleep.kv_rbac_propagation]
}
