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
  --encryption-services blob

# Create Blob Container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $SA_NAME
  
echo "Update your provider.tf with storage_account_name: $SA_NAME"