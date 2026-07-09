# Provisioning Manual

Execute sh script

Execute these commands in the directory containing the .tf files.

## Environments

Environment-specific configuration lives under `envs/<env>/`:

```
envs/
  dev/    dev.tfvars, backend.hcl    (the original values this repo shipped with)
  stage/  stage.tfvars, backend.hcl
  prod/   prod.tfvars, backend.hcl
```

Each `<env>.tfvars` sets `environment`, `resource_group_name`, `location`, and
`kubernetes_version`. The `environment` variable suffixes globally/tenant-unique
resource names (AKS, ACR, Key Vault, AGW, VNet, subnets, public IP) so all three
environments can coexist in the same subscription. Each `backend.hcl` sets only
the state file `key`, so each environment gets its own state in the shared
storage account/container.

`mysql_root_password` is sensitive and is intentionally NOT stored in any tfvars
file — always supply it via `TF_VAR_mysql_root_password` or a gitignored
`*.auto.tfvars` file.

## How to use it:

1. Set the sensitive variable securely (recommended via environment variable):

```bash
export TF_VAR_mysql_root_password="YourStrongPassword"
```

2. Initialize with the environment's backend config, then plan/apply with its tfvars:

```bash
terraform init -backend-config=envs/dev/backend.hcl -reconfigure

terraform plan -var-file=envs/dev/dev.tfvars -out main.tfplan

terraform apply "main.tfplan"

az aks get-credentials --resource-group rg-aks-andrii --name aks-andrii-dev --admin
```

Swap `dev` for `stage` or `prod` (and update the `--resource-group`/`--name` accordingly)
to target another environment.

## ArgoCD Installation via Helm:

```bash
kubectl create namespace argocd
helm repo add argo https://argoproj.github.io/argo-helm

helm upgrade argocd argo/argo-cd \
  --namespace argocd \
  -f yaml/argo-values.yaml

kubectl port-forward service/argocd-server -n argocd 8080:443
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Step-by-step: create Key Vault secret for MySQL password

1. Confirm you are in the right Azure subscription.

Command:

```bash
az account show --output table
```

2. Create or update the secret in Key Vault.

Command:

```bash
az keyvault secret set --vault-name kv-andrii --name DatabasePassword --value "YourStrongMysqlRootPasswordHere"
```

3. Verify the secret exists.

Command:

```bash
az keyvault secret show --vault-name kv-andrii --name DatabasePassword --query "id" -o tsv
```

4. Get the AKS Key Vault CSI identity Client ID from Terraform output (this is what goes into userAssignedIdentityID).

Command:

```bash
terraform output -raw aks_kv_csi_client_id
```

5. Put that value into secret-provider.yaml:11 at userAssignedIdentityID.

6. Apply the SecretProviderClass.

Command:

```bash
kubectl apply -f secret-provider.yaml
```

7. Restart MySQL pod so CSI mount + K8s secret sync is re-evaluated.

Command:

```bash
kubectl rollout restart deployment/mysql
```

8. Confirm the synced Kubernetes secret now exists.

Command:

```bash
kubectl get secret db-secret -o yaml
```

9. Confirm MySQL deployment is healthy.

Command:

```bash
kubectl rollout status deployment/mysql
```

10. Optional quick validation from pod environment (without printing full secret broadly).

Command:

```bash
kubectl exec deploy/mysql -- printenv MYSQL_DATABASE
```

http://<publicIp>/adminer