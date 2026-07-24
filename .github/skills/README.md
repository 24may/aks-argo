# Terraform Skills for This Repository

This folder contains repo-specific skills for working with the AKS + AGIC + ArgoCD Terraform stack.

## Available skills

1. `terraform-aks-provisioning`
   - End-to-end environment provisioning flow (`dev`/`stage`/`prod`) with backend + tfvars handling.
2. `terraform-aks-change-safety`
   - Safe Terraform change workflow and guardrails for naming, state, identities, and CI.
3. `terraform-aks-troubleshooting`
   - Fast diagnosis for common failures in AKS, AGIC, Key Vault CSI, and OIDC pipeline auth.
4. `kubernetes-aks-manifests`
   - Repo-specific guidance for AKS workload YAML, AGIC ingress, Key Vault CSI, NetworkPolicy, and ArgoCD `Application` manifests.
5. `helm-argocd-agic`
   - Safe Helm values workflow for ArgoCD behind Azure Application Gateway.

Use these files as prompt context for Copilot or as internal runbooks for contributors.