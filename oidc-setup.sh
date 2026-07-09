#!/bin/bash


# Переменные
APP_NAME="gh-oidc-terraform"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

# Создаём приложение и SP
APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)
az ad sp create --id "$APP_ID"

# Роль на нужный scope (subscription или resource group)
az role assignment create \
  --role "Contributor" \
  --assignee "$APP_ID" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"


# Федеративные учётные данные (по одной на ветку/окружение)

# Для PR (pull_request event)
az ad app federated-credential create --id "$APP_ID" --parameters '{
  "name": "gh-pr",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:24may/aks-argo:pull_request",
  "audiences": ["api://AzureADTokenExchange"]
}'

# Для main branch (apply)
az ad app federated-credential create --id "$APP_ID" --parameters '{
  "name": "gh-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:24may/aks-argo:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'

# Для GitHub Environment (рекомендуется для prod с approval)
az ad app federated-credential create --id "$APP_ID" --parameters '{
  "name": "gh-env-prod",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:24may/aks-argo:environment:prod",
  "audiences": ["api://AzureADTokenExchange"]
}'