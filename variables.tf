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