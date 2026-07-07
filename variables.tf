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
