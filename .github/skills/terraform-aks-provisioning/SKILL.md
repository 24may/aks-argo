# terraform-aks-provisioning

Provision and update the AKS + AGIC + ArgoCD platform in this repository across `dev`, `stage`, and `prod`.

## Use when

- You need to bootstrap or deploy an environment from this repo.
- You need the correct backend/tfvars command sequence for this project.
- You need to rotate the MySQL secret consumed through Key Vault CSI.

## Do not use when

- You are migrating from another cloud (use migration workflows).
- You need broad Azure architecture design from scratch.

## Repo-specific facts

- Terraform root is repository root (not inside `envs/`).
- Backend storage account/container is shared across all environments.
- State separation is only by backend `key` in `envs/<env>/backend.hcl`.
- Resource naming is environment-suffixed through `locals.tf`.
- Sensitive variable `mysql_root_password` has no default and must not be committed.

## Standard flow

1. One-time backend bootstrap:

```bash
./start-script.sh
```

2. Set sensitive variable:

```bash
export TF_VAR_mysql_root_password="<strong-password>"
```

3. Initialize Terraform for target environment:

```bash
terraform init -backend-config=envs/<env>/backend.hcl -reconfigure
```

4. Plan and apply:

```bash
terraform plan -var-file=envs/<env>/<env>.tfvars -out main.tfplan
terraform apply "main.tfplan"
```

5. Fetch AKS credentials:

```bash
az aks get-credentials --resource-group <rg-from-tfvars> --name aks-andrii-<env> --admin
```

## Secret rotation flow (MySQL)

1. Update Key Vault secret `DatabasePassword` in `kv-andrii-<env>`.
2. Get CSI identity client ID:

```bash
terraform output -raw aks_kv_csi_client_id
```

3. Put that value into `yaml/apps/secret-provider.yaml` at `userAssignedIdentityID`.
4. Apply manifest and restart MySQL deployment:

```bash
kubectl apply -f yaml/apps/secret-provider.yaml
kubectl rollout restart deployment/mysql
```

## Guardrails

- Never put secrets in `envs/*.tfvars`.
- Keep `environment` as one of `dev|stage|prod`.
- Keep ACR name alphanumeric (no dashes) to satisfy Azure naming rules.
- Preserve AGIC + Key Vault role assignments when refactoring.
