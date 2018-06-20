#!/bin/bash -ex

# Login to your Azure account
az login --service-principal -u $AZURE_MGMT_CLIENT_ID -p $AZURE_MGMT_CLIENT_SECRET --tenant $AZURE_TENANT_ID

# Prompt for resource names, location etc
echo "Enter location:"
read location

echo "Enter resource group name:"
read rg_name
echo "Enter key vault name:"
read kv_name
echo "Enter SP object id to access KeyVault:"
read kv_user
echo "Enter storage account name:"
read sa_name

# Create resource group
az group create --name $rg_name --location $location

# Create KeyVault and save keyvault_url
keyvault_url=$(az keyvault create --name $kv_name --resource-group $rg_name | grep "vaultUri" | cut -d '"' -f 4)
# Update KeyVault policy for provided object id:
#    Certificates -- import (upload custom certificate to the key vault)
#    Secret -- set (upload custom secret to the key vault)
az keyvault set-policy --name $kv_name --certificate-permissions import --secret-permissions set --object-id $kv_user

# Create storage account
az storage account create --name $sa_name --resource-group $rg_name

# Retrieve storage account key to generate SAS token
storage_key=$(az storage account keys list --account-name $sa_name --resource-group $rg_name | grep "value" | head -1 | cut -d '"' -f 4)

# Output results
echo "storage account name:" $sa_name
echo "Vault name:" $kv_name
echo "Vault url:" $keyvault_url

# Export environment variables
export AZURE_STORAGE_KEY=$storage_key
export AZURE_KEY_VAULT_NAME=$kv_name
export AZURE_KEY_VAULT_URL=$keyvault_url
export AZURE_STORAGE_NAME=$sa_name