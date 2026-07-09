#!/bin/bash

# Define variables
RG_NAME="rg-aks-andrii"
LOCATION="polandcentral"
SA_NAME="sttfstateandrii" # Random suffix for global uniqueness
CONTAINER_NAME="tfstate"

# Create Resource Group
az group create --name $RG_NAME --location $LOCATION

# Create Storage Account
az storage account create \
  --name $SA_NAME \
  --resource-group $RG_NAME \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob \
  --allow-blob-public-access false \
  --min-tls-version TLS1_2

# Enable blob versioning + soft delete + change feed so a corrupted/overwritten
# state blob (interrupted apply, accidental manual upload, force-unlock gone
# wrong, etc.) can always be restored to a previous version instead of being
# lost. This is the primary safety net for the remote state file.
az storage account blob-service-properties update \
  --account-name $SA_NAME \
  --resource-group $RG_NAME \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days 30 \
  --enable-container-delete-retention true \
  --container-delete-retention-days 30 \
  --enable-change-feed true

# Create Blob Container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $SA_NAME

echo "Update your provider.tf with storage_account_name: $SA_NAME"
echo "State blob recovery: az storage blob list --account-name $SA_NAME -c $CONTAINER_NAME --include v  (list versions)"
echo "                     az storage blob copy start --destination-blob <key> --destination-container $CONTAINER_NAME --account-name $SA_NAME --source-uri '<version-url>'  (restore a version)"