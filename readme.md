Provisioning Manual

Execute sh script

Execute these commands in the directory containing the .tf files:

terraform init

terraform plan -out main.tfplan

terraform apply "main.tfplan"

az aks get-credentials --resource-group rg-aks-andrii --name aks-andrii --admin


ArgoCD Installation via Helm:

kubectl create namespace argocd
helm repo add argo https://argoproj.github.io/argo-helm

helm upgrade argocd argo/argo-cd \
  --namespace argocd \
  -f yaml/argo-values.yaml

  kubectl port-forward service/argocd-server -n argocd 8080:443
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d