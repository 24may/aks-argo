# kubernetes-aks-manifests

Create, review, and safely modify Kubernetes YAML manifests in this AKS + AGIC + ArgoCD repository.

## Use when

- Editing files under `yaml/` or `yaml/apps/`.
- Adding or changing Deployments, Services, Ingresses, PVCs, SecretProviderClass objects, NetworkPolicies, or ArgoCD `Application` manifests.
- Checking whether a manifest change fits this repo's AKS + Application Gateway constraints.

## Do not use when

- The change is primarily Terraform infrastructure work.
- The change is mainly Helm chart authoring in `yaml/argo-values.yaml`.

## Repo-specific facts

- Application workloads in this repo are plain YAML manifests under `yaml/apps/`.
- ArgoCD `Application` resources live in `yaml/` and point at GitOps content.
- Ingress traffic is handled by AGIC through `ingressClassName: azure-application-gateway`.
- The current Application Gateway setup is HTTP-only. There is no TLS listener provisioned in Terraform.
- Secrets are synced from Azure Key Vault through Secrets Store CSI using `SecretProviderClass`.

## Manifest guardrails

1. Ingress rules
   - Use `ingressClassName: azure-application-gateway` instead of the legacy ingress-class annotation.
   - Keep `appgw.ingress.kubernetes.io/ssl-redirect: "false"` unless Terraform adds a real HTTPS listener and certificate.
   - Keep `appgw.ingress.kubernetes.io/backend-protocol: "http"` for current workloads unless the backend actually serves HTTPS.
   - Include health-probe annotations when needed so AGIC does not mark backends unhealthy.

2. SecretProviderClass and Key Vault CSI
   - Keep `provider: azure` and the managed-identity pattern already used in `yaml/apps/secret-provider.yaml`.
   - `keyvaultName` must match the target environment naming convention such as `kv-andrii-dev`.
   - `userAssignedIdentityID` must come from `terraform output -raw aks_kv_csi_client_id` for the deployed cluster.
   - If a workload consumes a synced Kubernetes secret, make sure `secretObjects` and the pod's `secretKeyRef` stay aligned.

3. Stateful workloads
   - Treat MySQL as single-replica unless clustering/storage design changes intentionally.
   - Preserve `Recreate` strategy with `ReadWriteOnce` Azure Disk unless storage semantics are changed deliberately.

4. Network policy
   - If you tighten traffic rules, verify all intended callers are explicitly allowed.
   - Keep label selectors consistent with the workload labels used in the matching Deployment manifests.

5. ArgoCD applications
   - Keep `destination.server: 'https://kubernetes.default.svc'` unless the repo is intentionally targeting another cluster.
   - Prefer automated sync settings only when self-heal and prune are actually intended.

## Common change patterns

- New application exposure:
  1. Add or update a Deployment.
  2. Add a matching Service.
  3. Add an AGIC-compatible Ingress with HTTP-oriented annotations.

- New secret-backed workload:
  1. Add or extend `SecretProviderClass` objects.
  2. Sync the required Key Vault object into a Kubernetes secret if env-var consumption is needed.
  3. Mount or reference the secret from the workload.

- ArgoCD onboarding:
  1. Add or update an `Application` resource in `yaml/`.
  2. Verify `repoURL`, `path`, `targetRevision`, and target namespace.

## Validation flow

- Prefer `kubectl apply --dry-run=client -f <file>` for touched manifests when available.
- For multi-document files, validate the whole file, not one pasted section.
- After secret or rollout-related changes, check workload behavior with `kubectl get pods -A` and `kubectl describe` on the affected pod.

## Anti-patterns

- Reintroducing `kubernetes.io/ingress.class` as the primary ingress selector.
- Enabling SSL redirect without matching Application Gateway TLS infrastructure.
- Hardcoding environment-specific Key Vault values without considering `dev`/`stage`/`prod` differences.
- Scaling MySQL or changing storage access assumptions casually.
