# helm-argocd-agic

Safely edit Helm values and chart-facing configuration for ArgoCD in this AKS + AGIC repository.

## Use when

- Modifying `yaml/argo-values.yaml`.
- Preparing a Helm upgrade for ArgoCD in this cluster.
- Reviewing Helm values that affect ingress, server protocol, or AGIC behavior.

## Do not use when

- You are editing plain workload manifests under `yaml/apps/`.
- The task is a Terraform change to Application Gateway, AKS, or identities.

## Repo-specific facts

- ArgoCD is installed from the upstream `argo/argo-cd` Helm chart.
- This repo stores Helm customizations in `yaml/argo-values.yaml`.
- ArgoCD is intentionally exposed over HTTP because the Application Gateway only has an HTTP frontend listener today.
- AGIC is the ingress controller, so ArgoCD Helm values must stay compatible with Azure Application Gateway annotations.

## Helm guardrails

1. Server protocol and ingress
   - Keep `configs.params.server.insecure: true` while ArgoCD is served behind HTTP-only ingress.
   - Keep `server.ingress.enabled: true` only if the chart should continue managing the ingress.
   - Preserve `server.ingress.ingressClassName: azure-application-gateway`.
   - Keep `servicePort: http` aligned with the insecure server configuration.

2. AGIC annotations
   - Keep `appgw.ingress.kubernetes.io/ssl-redirect: "false"` until Terraform provisions HTTPS listener support.
   - Keep `appgw.ingress.kubernetes.io/backend-protocol: "http"` unless ArgoCD server is explicitly switched to HTTPS end to end.
   - Preserve health-probe overrides when needed to avoid AGW backend health failures.

3. Hostnames and exposure
   - Keep host/domain changes consistent between `global.domain` and `server.ingress.hosts`.
   - If changing DNS strategy, verify the chosen hostname still resolves to the AGW public endpoint used by the cluster.

4. Upgrade hygiene
   - Prefer values-only changes over broad chart behavior changes unless the chart version or deployment model is intentionally changing.
   - If a new chart value depends on Terraform-side networking or TLS support, call that dependency out explicitly before enabling it.

## Standard workflow

1. Update `yaml/argo-values.yaml`.
2. Review whether the change affects AGIC annotations, server protocol, hostname, or service port.
3. Validate rendered behavior with a Helm dry run when Helm is available.
4. Apply with the repo's existing ArgoCD Helm install command.

## Validation flow

- Prefer:

```bash
helm upgrade --install argocd argo/argo-cd --namespace argocd --create-namespace -f yaml/argo-values.yaml --dry-run
```

- If dry-run output looks correct, use the same command without `--dry-run` when deployment is intended.

## Anti-patterns

- Turning on SSL redirect without adding corresponding HTTPS infrastructure in Terraform.
- Changing `servicePort` away from `http` while `server.insecure` remains enabled.
- Mixing unrelated chart changes with ingress troubleshooting in one edit.
