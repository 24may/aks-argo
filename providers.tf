terraform {
  required_version = ">= 1.15.0"
  # key (state file path) is env-specific and supplied via -backend-config,
  # see envs/<env>/backend.hcl (e.g. terraform init -backend-config=envs/dev/backend.hcl)
  backend "azurerm" {
    resource_group_name  = "rg-aks-andrii"
    storage_account_name = "sttfstateandrii"
    container_name       = "tfstate"
    use_oidc               = true
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.79.0" # Upgraded to resolve deprecated API version
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.12.0"
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