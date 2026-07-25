# terraform-aks-change-safety

Apply safe, low-regression Terraform changes in this AKS + AGIC repository.

## Use when

- Adding or modifying Azure resources in Terraform.
- Preparing pull requests that change `.tf`, `*.tfvars`, or backend config.
- Extending to new environments or updating CI/OIDC wiring.

## Key risks in this repo

- Name collisions across environments if resources bypass `locals.tf`.
- Broken AGIC reconciliation if subnet/join roles are removed.
- Key Vault secret provisioning failures due to RBAC propagation timing.
- Cross-environment state mistakes if wrong backend key is used.

## Safe change checklist

1. Naming and environment isolation
   - Define new names in `locals.tf` and derive from `var.environment`.
   - Do not hardcode bare names that can collide across `dev/stage/prod`.

2. Plan hygiene
   - Reinitialize with the correct backend key per environment.
   - Use `terraform plan -var-file=envs/<env>/<env>.tfvars -out main.tfplan`.
   - Review destructive actions explicitly before apply.

3. Identity and RBAC
   - Preserve these role assignment intents:
     - AKS kubelet -> `AcrPull` on ACR.
     - AKS Key Vault CSI identity -> `Key Vault Secrets User` on Key Vault.
     - AGIC identity -> `Contributor` on AGW, `Network Contributor` on AGW subnet, `Reader` on RG.

4. CI/OIDC alignment
   - If adding a new environment, add matching federated credential subject in `oidc-setup.sh`.
   - Ensure GitHub Actions variables exist: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`.

5. Validation before merge
   - `terraform fmt -check`
   - `terraform validate`
   - `terraform plan` for each impacted environment

## Change patterns

- New resource pattern:
  1. Add local name in `locals.tf`.
  2. Reference local in new resource block.
  3. Wire to existing network, identity, and outputs only as needed.
- New environment pattern:
  1. Add `envs/<env>/<env>.tfvars` and `envs/<env>/backend.hcl`.
  2. Add matching GitHub environment and OIDC federated credential.
  3. Validate with targeted plan/apply.

## Anti-patterns

- Editing backend shared account/container names casually.
- Committing sensitive values into tracked files.
- Removing `time_sleep` before validating RBAC propagation behavior.
