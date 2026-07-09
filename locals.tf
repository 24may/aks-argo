# Centralized naming convention: every resource that is globally/tenant-unique
# or could collide across environments (dev/stage/prod) sharing the same
# subscription is suffixed with var.environment.
locals {
  aks_name     = "aks-andrii-${var.environment}"
  agw_name     = "agw-aks-andrii-${var.environment}"
  vnet_name    = "vnet-aks-andrii-${var.environment}"
  aks_subnet   = "snet-aks-${var.environment}"
  agw_subnet   = "snet-agw-${var.environment}"
  pip_name     = "pip-agw-andrii-${var.environment}"
  acr_name     = "acrandrii${var.environment}" # ACR names: alphanumeric only, no dashes
  kv_name      = "kv-andrii-${var.environment}"
  node_rg_name = "MC_${var.resource_group_name}_${local.aks_name}_eu"
}
