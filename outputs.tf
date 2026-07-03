# Output the exact Client ID required for the SecretProviderClass
output "aks_kv_csi_client_id" {
  description = "The Client ID of the User Assigned Identity for the AKS Key Vault CSI Driver"
  value       = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].client_id
}

# Output the Object ID for RBAC assignments (Already used in modules.tf)
output "aks_kv_csi_object_id" {
  description = "The Object ID of the User Assigned Identity for Key Vault RBAC"
  value       = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].object_id
}