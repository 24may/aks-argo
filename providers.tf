terraform {
  required_version = ">= 1.15.0"
  backend "azurerm" {
    resource_group_name  = "rg-aks-andrii"
    storage_account_name = "sttfstateandrii"
    container_name       = "tfstate"
    key                  = "aks.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.79.0" # Upgraded to resolve deprecated API version
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  subscription_id = "943707bc-becc-4d25-a039-78c22cbc7fc3" # Required in v4.x
}