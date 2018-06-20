#!/bin/bash -ex

# ensure AZURE_KEY_VAULT_NAME is configured
: "${AZURE_KEY_VAULT_NAME?"Need to set AZURE_KEY_VAULT_NAME"}"

echo "Uploading vm files"

# Package & upload files to Azure. 
# upload_files.py returns string in the format: 
#    export TF_VAR_files=["file1", "file2"]
# eval is used to export TF_VAR_files for terraform deployment.
eval $(python3 upload_files.py)

cd ../deployment/terraform

# Login to Azure
echo "Logging into Azure"
az login --service-principal -u $AZURE_MGMT_CLIENT_ID -p $AZURE_MGMT_CLIENT_SECRET --tenant $AZURE_TENANT_ID

echo "Running terraform"
terraform init # Initialize terraform. No effect if was initialized.

# Configure terraform variables
export TF_VAR_client_id=$AZURE_MGMT_CLIENT_ID
export TF_VAR_client_secret=$AZURE_MGMT_CLIENT_SECRET
export TF_VAR_tenant_id=$AZURE_TENANT_ID
export TF_VAR_subscription_id=$AZURE_SUBSCRIPTION_ID
export TF_VAR_command="bash bootstrap.sh $AZURE_KEY_VAULT_URL"

# Run terraform apply and save output to the file to extract VMSS MSI SP
terraform apply | tee log.txt

# Extract VMSS MSI SP
vmss_sp=$(cat log.txt | grep --color=never -Po "VMSS SPN[\s=a-zA-Z0-9\-]+" | cut -d ' ' -f 4)
echo "vmss_sp =" $vmss_sp
echo "keyvault_name = " $AZURE_KEY_VAULT_NAME

# Remove terraform log file
rm log.txt

# Update KV policy:
#     Certificates: get to retrieve the certificate
#     Secrets: get to retrieve secrets
echo "Setting KV policy"
az keyvault set-policy --name $AZURE_KEY_VAULT_NAME --certificate-permissions get --secret-permissions get --object-id $vmss_sp
echo "Success!"
