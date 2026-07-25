---
applyTo: "yaml/argo-values.yaml"
---

# Helm Values Instructions

## Scope

- This repository currently customizes the ArgoCD Helm release through `yaml/argo-values.yaml`.
- These values are for the upstream `argo/argo-cd` chart running on AKS behind AGIC.
- Treat this file as Helm values, not as a plain application manifest.

## Change Rules

- Prefer values-only changes. Do not restructure unrelated keys unless the chart behavior requires it.
- Keep changes minimal and coherent with the existing ArgoCD deployment model.
- When changing a value tied to ingress, server protocol, or exposure, verify the dependent values in the same edit.

## ArgoCD And AGIC Constraints

- Keep `configs.params.server.insecure: true` while ArgoCD is served through the current HTTP-only Application Gateway listener.
- Keep `server.ingress.ingressClassName: azure-application-gateway`.
- Keep `servicePort: http` aligned with the insecure server setup unless the deployment is intentionally migrated to end-to-end HTTPS.
- Keep `appgw.ingress.kubernetes.io/ssl-redirect: "false"` until Terraform provisions HTTPS listener and certificate support.
- Keep `appgw.ingress.kubernetes.io/backend-protocol: "http"` unless ArgoCD server itself is reconfigured to serve HTTPS to the gateway.
- Preserve health-probe annotations when they are needed to keep AGW backend health green.

## Hostname And Exposure Rules

- Keep `global.domain` and `server.ingress.hosts` consistent with each other.
- If the hostname changes, confirm it still maps to the Application Gateway public endpoint used by this cluster.
- Do not enable TLS-related chart values unless the matching gateway listener, certificate, and DNS setup exist outside Helm.

## Validation Expectations

- After editing `yaml/argo-values.yaml`, prefer validating with:

```bash
helm upgrade --install argocd argo/argo-cd --namespace argocd --create-namespace -f yaml/argo-values.yaml --dry-run
```

- If dry-run is unavailable, at least review the affected ingress, server, and host-related keys together before considering the edit complete.

## Editing Heuristics For AI Agents

- Start from the value that directly controls the requested behavior: `configs.params` for ArgoCD server flags, `server.ingress` for exposure, and annotations for AGIC-specific behavior.
- Avoid mixing chart-behavior changes with unrelated troubleshooting cleanups in the same edit.
- Preserve concise comments that document why HTTP-only behavior exists today.
