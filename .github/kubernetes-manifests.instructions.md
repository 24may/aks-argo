---
applyTo: "yaml/**/*.yaml"
---

# Kubernetes Manifest Instructions

## Scope

- This repository stores Kubernetes manifests under `yaml/` and `yaml/apps/`.
- Most workload manifests are plain YAML, not Helm templates.
- Treat these files as AKS-targeted manifests behind Azure Application Gateway Ingress Controller (AGIC).

## Change Rules

- Prefer small, targeted manifest edits. Do not reformat unrelated documents in multi-document YAML files.
- Preserve existing document boundaries in files that contain multiple resources separated by `---`.
- Keep names, labels, selectors, namespaces, and secret references aligned across related resources.
- When adding a new workload, wire the minimum required Kubernetes objects: usually Deployment, Service, and Ingress only when external exposure is needed.

## Ingress And AGIC Conventions

- Use `ingressClassName: azure-application-gateway` for ingress resources.
- Do not switch back to `kubernetes.io/ingress.class` as the primary ingress selector.
- Keep `appgw.ingress.kubernetes.io/ssl-redirect: "false"` unless Terraform also provisions HTTPS listener and certificate support on the Application Gateway.
- Keep `appgw.ingress.kubernetes.io/backend-protocol: "http"` unless the backend workload is explicitly configured to serve HTTPS.
- Preserve or add health-probe annotations when the backend path is not obvious to AGIC.

## Secret And Identity Conventions

- This repo uses Azure Key Vault via Secrets Store CSI and `SecretProviderClass`.
- Keep `provider: azure` and the existing managed identity pattern unless the infrastructure model changes deliberately.
- `keyvaultName` should follow the environment naming convention such as `kv-andrii-dev`, `kv-andrii-stage`, or `kv-andrii-prod`.
- `userAssignedIdentityID` should match `terraform output -raw aks_kv_csi_client_id` from the corresponding deployed environment.
- If a pod reads from a Kubernetes secret synced by CSI, keep `secretObjects` keys aligned with the pod's `secretKeyRef` keys.

## Workload Constraints

- Treat MySQL as a single-replica stateful workload unless a deliberate clustering or storage redesign is part of the change.
- Preserve `Recreate` strategy when a workload mounts a `ReadWriteOnce` volume that must not be attached to multiple pods simultaneously.
- Keep PVC size, storage class, and mount paths stable unless the change intentionally alters persistence behavior.

## Network Policy And Labeling

- Keep pod labels, selectors, and NetworkPolicy selectors consistent.
- If a NetworkPolicy selects a pod, verify every required caller is explicitly allowed before tightening rules.
- Avoid changing labels on live workloads unless matching selectors are updated in every dependent Service, Deployment, and NetworkPolicy.

## ArgoCD Application Manifests

- ArgoCD `Application` resources in `yaml/` should continue targeting `https://kubernetes.default.svc` unless the repo is intentionally managing another cluster.
- Check `repoURL`, `path`, `targetRevision`, and destination namespace together; these fields are coupled.
- Keep automated sync, prune, and self-heal settings only when that behavior is intended.

## Validation Expectations

- After manifest edits, prefer `kubectl apply --dry-run=client -f <file>` for the touched file when `kubectl` is available.
- Validate the whole YAML file, not just one extracted document, especially for multi-document files.
- For secret sync or rollout changes, verify the affected workload with `kubectl get pods -A`, `kubectl describe pod`, or `kubectl get events -A --sort-by=.lastTimestamp` when relevant.

## Editing Heuristics For AI Agents

- Start with the resource that directly controls behavior: Deployment for container/runtime changes, Service for traffic wiring, Ingress for exposure, SecretProviderClass for secret sync, NetworkPolicy for connectivity, and ArgoCD `Application` for GitOps targeting.
- Preserve existing comments that explain AGIC, HTTP-only ingress, or secret sync constraints.
- Keep environment-specific values deliberate. Do not casually hardcode a `dev` value into manifests that may later be promoted to another environment without noting the implication.
