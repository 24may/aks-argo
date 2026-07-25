# terraform-aks-troubleshooting

Troubleshoot common deployment and runtime issues for this Terraform-managed AKS + AGIC + Key Vault setup.

## Use when

- `terraform apply` fails around Key Vault, AKS, or role assignments.
- Ingress through Application Gateway is not reconciling.
- Pods fail to read secrets from Key Vault CSI.
- GitHub Actions OIDC login fails.

## High-probability failure map

1. Key Vault secret creation fails with `403 ForbiddenByRbac`
   - Cause: RBAC assignment not yet propagated.
   - Check: `azurerm_role_assignment.kv_secrets_officer_caller` and `time_sleep.kv_rbac_propagation` exist and are ordered.
   - Action: re-run apply after propagation delay.

2. AGIC cannot push AGW config
   - Symptom: errors like `ApplicationGatewayInsufficientPermissionOnSubnet`.
   - Cause: missing AGIC `Network Contributor` on AGW subnet.
   - Check role assignments in `modules.tf` for AGIC identity scope.

3. CSI secret not syncing to Kubernetes secret
   - Check `yaml/apps/secret-provider.yaml`:
     - `keyvaultName` matches environment (`kv-andrii-<env>`).
     - `userAssignedIdentityID` equals `terraform output -raw aks_kv_csi_client_id`.
     - Namespace and secret object mapping are correct.
   - Then restart workload: `kubectl rollout restart deployment/mysql`.

4. OIDC pipeline auth failures in GitHub Actions
   - Common message: missing values for `azure/login`.
   - Verify repo/action variables exist and match Entra app setup.
   - Verify federated credential subject matches event type (`pull_request`, branch, or environment).

5. Wrong environment planned/applied
   - Cause: mismatched `backend.hcl` key and tfvars file.
   - Action: re-run `terraform init -backend-config=envs/<env>/backend.hcl -reconfigure` and re-plan.

## Fast triage commands

```bash
terraform state list
terraform output
kubectl get pods -A
kubectl describe pod <pod> -n <namespace>
kubectl get events -A --sort-by=.lastTimestamp
```

## Escalation notes

- For AGIC identity issues, confirm the auto-created identity name format remains `ingressapplicationgateway-<aks-name>`.
- For Key Vault issues, verify RBAC mode remains enabled and role scopes are unchanged.
