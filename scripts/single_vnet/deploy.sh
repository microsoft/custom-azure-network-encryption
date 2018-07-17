#!/bin/bash -ex

# ensure AZURE_KEY_VAULT_NAME is configured
: "${AZURE_KEY_VAULT_NAME?"Need to set AZURE_KEY_VAULT_NAME"}"

cd ../

echo "Generating certificates"
python3 generate_certificates.py "single_vnet/hostnames.json"

echo "Uploading vm files"
# Package & upload files to Azure. 
# upload_files.py returns string in the format: 
#    export TF_VAR_files=["file1", "file2"]
# eval is used to export TF_VAR_files for terraform deployment.
eval $(python3 upload_files.py)

cd ../deployment/single_vnet

echo "Running terraform"
terraform init # Initialize terraform. No effect if was initialized.

# Set defaults for subnet
subnet_address_space='["10.0.0.0/16"]'
subnet_address_prefix=10.0.0.0/24

# Configure terraform variables
export TF_VAR_client_id=$AZURE_MGMT_CLIENT_ID
export TF_VAR_client_secret=$AZURE_MGMT_CLIENT_SECRET
export TF_VAR_tenant_id=$AZURE_TENANT_ID
export TF_VAR_subscription_id=$AZURE_SUBSCRIPTION_ID
export TF_VAR_vnet_address_space=$subnet_address_space
export TF_VAR_vnet_subnet_address_prefix=$subnet_address_prefix
export TF_VAR_command="bash bootstrap.sh $AZURE_KEY_VAULT_URL $subnet_address_prefix"
export TF_VAR_keyvault_name=$AZURE_KEY_VAULT_NAME
export TF_VAR_keyvault_resource_group_name=$AZURE_KEY_VAULT_RESOURCE_GROUP

# Run terraform apply and save output to the file to extract VMSS MSI SP
terraform apply
