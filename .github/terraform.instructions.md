---
applyTo: '**/*.{tf,tfvars,hcl}'
---

# Terraform Instructions

## Scope

- This repository's Terraform root is the repository root.
- `envs/dev`, `envs/stage`, and `envs/prod` only store environment-specific `*.tfvars` and backend `*.hcl` files.
- Keep Terraform changes aligned with the current AKS + Application Gateway + ArgoCD architecture.

## Change Rules

- Prefer small, targeted Terraform changes. Do not refactor unrelated resources or rename existing resources without a clear reason.
- When adding a new configurable input, declare it in `variables.tf`, thread it through the relevant resources, and set environment-specific values in the matching `envs/<env>/<env>.tfvars` file only when needed.
- When adding a new output, place it in `outputs.tf` and keep the name descriptive and stable.
- Keep resource definitions in the existing root-module layout unless there is a strong reason to introduce a module.

## Naming And Environment Conventions

- Derive new Azure resource names in `locals.tf` from `var.environment` instead of hardcoding literal names.
- Preserve the existing per-environment naming pattern so `dev`, `stage`, and `prod` can coexist in the same subscription.
- Keep Azure Container Registry names alphanumeric-only. Do not introduce dashes into ACR names.
- If a resource must be globally unique, make that explicit in `locals.tf` and follow the same suffixing pattern already used by AKS, AGW, Key Vault, VNet, and public IP resources.

## State And Environment Handling

- Do not hardcode an environment-specific backend `key` in `providers.tf`; it must stay supplied through `terraform init -backend-config=envs/<env>/backend.hcl`.
- Keep the shared backend storage account, container, and OIDC-based backend authentication intact unless the change explicitly migrates state handling.
- Treat `envs/<env>/backend.hcl` as the source of truth for state-file separation between environments.

## Secrets And Security

- Never commit secret values into Terraform files, `*.tfvars`, shell scripts, or documentation.
- `mysql_root_password` must remain a sensitive variable and should be provided through `TF_VAR_mysql_root_password` or another non-committed mechanism.
- Preserve Key Vault RBAC-based access unless the change explicitly requires a different authorization model.
- Be careful with identity and role-assignment changes. Existing AGIC and Key Vault CSI permissions are load-bearing.

## AKS And Networking Constraints

- Preserve the Application Gateway integration used by the AKS cluster unless the task explicitly changes ingress architecture.
- Do not remove or weaken the AGIC role assignments on the Application Gateway, its subnet, or the resource group without replacing them with an equivalent working model.
- Keep the current HTTP-only Application Gateway assumption in mind; do not add Terraform references to TLS listeners or certificates unless the full listener configuration is added consistently.

## Validation Expectations

- After Terraform changes, prefer validating from the repository root.
- Run `terraform fmt` on touched Terraform files when formatting changes are needed.
- Run `terraform validate` for structural validation.
- When the change affects behavior, run `terraform plan -var-file=envs/<env>/<env>.tfvars` for at least one relevant environment before considering the work complete.

## Editing Heuristics For AI Agents

- Check `locals.tf` first when the change involves names or environment-specific resource identity.
- Check `variables.tf` and `envs/<env>/<env>.tfvars` first when the change involves configuration inputs.
- Check `providers.tf` before changing provider versions, backend behavior, or authentication settings.
- Keep comments concise and only add them where the Terraform intent is not obvious from the code.