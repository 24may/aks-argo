variable "environment" {
  description = "Deployment environment. Used to suffix globally/tenant-unique resource names (ACR, Key Vault, AKS, AGW, VNet, etc.) so dev/stage/prod can coexist."
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment must be one of: dev, stage, prod."
  }
}

variable "resource_group_name" {
  type    = string
  default = "rg-aks-andrii"
}

variable "location" {
  type    = string
  default = "polandcentral"
}

variable "kubernetes_version" {
  type    = string
  default = "1.34.8"
}

variable "mysql_root_password" {
  description = "MySQL root password stored as DatabasePassword secret in Key Vault"
  type        = string
  sensitive   = true
}
