#!/bin/bash -ex

# ensure AZURE_KEY_VAULT_NAME is configured
: "${AZURE_KEY_VAULT_NAME?"Need to set AZURE_KEY_VAULT_NAME"}"

cd ../

echo "Generating certificates"
python3 generate_certificates.py "two_vnets/hostnames.json"

echo "Uploading vm files"
# Package & upload files to Azure. 
# upload_files.py returns string in the format: 
#    export TF_VAR_files=["file1", "file2"]
# eval is used to export TF_VAR_files for terraform deployment.
eval $(python3 upload_files.py)

cd ../deployment/two_vnets

# Login to Azure
echo "Logging into Azure"
az login --service-principal -u $AZURE_MGMT_CLIENT_ID -p $AZURE_MGMT_CLIENT_SECRET --tenant $AZURE_TENANT_ID

echo "Running terraform"
terraform init # Initialize terraform. No effect if was initialized.

# Set defaults for subnet
subnet_address_space_1='["10.0.0.0/16"]'
subnet_address_prefix_1=10.0.0.0/24
subnet_gateway_address_prefix_1=10.0.1.0/24

subnet_address_space_2='["172.0.0.0/16"]'
subnet_address_prefix_2=172.0.0.0/24
subnet_gateway_address_prefix_2=172.0.1.0/24

# Configure terraform variables
export TF_VAR_client_id=$AZURE_MGMT_CLIENT_ID
export TF_VAR_client_secret=$AZURE_MGMT_CLIENT_SECRET
export TF_VAR_tenant_id=$AZURE_TENANT_ID
export TF_VAR_subscription_id=$AZURE_SUBSCRIPTION_ID
export TF_VAR_vnet_address_space_1=$subnet_address_space_1
export TF_VAR_vnet_subnet_address_prefix_1=$subnet_address_prefix_1
export TF_VAR_vnet_gateway_subnet_address_prefix_1=$subnet_gateway_address_prefix_1
export TF_VAR_vnet_address_space_2=$subnet_address_space_2
export TF_VAR_vnet_subnet_address_prefix_2=$subnet_address_prefix_2
export TF_VAR_vnet_gateway_subnet_address_prefix_2=$subnet_gateway_address_prefix_2
export TF_VAR_command="bash bootstrap.sh $AZURE_KEY_VAULT_URL $subnet_address_prefix_1 $subnet_address_prefix_2"

# Run terraform apply and save output to the file to extract VMSS MSI SP
terraform apply | tee log.txt

# Extract VMSS MSI SP
vmss_sp_1=$(cat log.txt | grep --color=never -Po "VMSS_SPN1[\s=a-zA-Z0-9\-]+" | cut -d ' ' -f 3)
vmss_sp_2=$(cat log.txt | grep --color=never -Po "VMSS_SPN2[\s=a-zA-Z0-9\-]+" | cut -d ' ' -f 3)
echo "vmss_sp1 =" $vmss_sp_1
echo "vmss_sp2 =" $vmss_sp_2
echo "keyvault_name = " $AZURE_KEY_VAULT_NAME

# Remove terraform log file
rm log.txt

# Update KV policy:
#     Certificates: get to retrieve the certificate
#     Secrets: get to retrieve secrets
echo "Setting KV policy"
az keyvault set-policy --name $AZURE_KEY_VAULT_NAME --certificate-permissions get --secret-permissions get --object-id $vmss_sp_1
az keyvault set-policy --name $AZURE_KEY_VAULT_NAME --certificate-permissions get --secret-permissions get --object-id $vmss_sp_2
echo "Success!"
