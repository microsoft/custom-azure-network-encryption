## Create Service Principals

You need to create required Service Principals. You will need at least 2 different SPs: 
- SP to deploy the infrastructure
- SP to upload certificates to the Azure Key Vault

First, let's create deployment SP. You can run following commands to do this.
``` console
az login
az account set --subscription="SUBSCRIPTION_ID"
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/SUBSCRIPTION_ID" --name DeploymentSP
```

This command will ouput five values:
``` console
{
  "appId": "00000000-0000-0000-0000-000000000000",
  "displayName": "DeploymentSP",
  "name": "http://DeploymentSP",
  "password": "0000-0000-0000-0000-000000000000",
  "tenant": "00000000-0000-0000-0000-000000000000"
}
```

If you use the following helper scripts from this repo, please save the environment variables:
``` console
export AZURE_TENANT_ID=<tenant>
export AZURE_SUBSCRIPTION_ID=<SUBSCRIPTION_ID>

export AZURE_MGMT_CLIENT_ID=<appId>
export AZURE_MGMT_CLIENT_SECRET=<password>
```

Now we can create a Key Vault user, this user doesn't require any assigned role because access will be configured later. Also, we will obtain the SP object ID. Object ID will be used to grant access to Key Vault. We can use the SP name, but if do this deployment SP needs an access to Active Directory.

``` console
az ad sp create-for-rbac --skip-assignment --name KeyVaultSP
az ad sp show --id <appId>
```

The output from the second command will look like this:
``` console
{
  "appId": "00000000-0000-0000-0000-000000000000",
  "displayName": "KeyVaultSP",
  "objectId": "00000000-0000-0000-0000-000000000000",
  "objectType": "ServicePrincipal",
  "servicePrincipalNames": [
    "http://KeyVaultSP",
    "00000000-0000-0000-0000-000000000000"
  ]
}
```

When a user is created, export the corresponding environment variables:
``` console
export AZURE_KEY_VAULT_CLIENT_ID=<appId>
export AZURE_KEY_VAULT_CLIENT_SECRET=<password>
export AZURE_KEY_VAULT_CLIENT_OBJECT_ID=<objectId>
```

## Create Required Infrastructure

After the service principal is created, we can now deployed required infrastructure.
This solution requires Azure Key Vault and Azure Storage Account.
You can run `scripts/initialization/create_infra.sh` script, it will do everything described in this section.

First we will create a new resource group.

``` console
az group create --name <resource_group_name> --location <location>
```

Second, let's create Azure Key Vault and configure its policies.
We will configure two policies for the SP created in the previous section.

- Certificates: Enable the `import` policy. We should now be able to upload the provisioned certificates to Key Vault.
- Secrets: Enable the `set` policy. We should now be able to create new secrets in Key Vault.

``` console
az keyvault create --name <key_vault_name> --resource-group <resource_group_name>
az keyvault set-policy --name <key_vault_name> --certificate-permissions import --secret-permissions set --object-id $AZURE_KEY_VAULT_CLIENT_OBJECT_ID
```

The Key Vault create command returns the Vault Url. Also, we will need the Key Vault name in the future. Let's save both.

``` console
export AZURE_KEY_VAULT_NAME=<key_vault_name>
export AZURE_KEY_VAULT_URL=<key_vault_url>
```

Now we can provision the storage account. We use Azure Storage Account as a source of files for Azure VM Custom Script extension. This extension allows you to specify files you want to be downloaded to the VM during provisioning and also specify a command to run.

The key is required to generate SAS tokens. We will be pass this to the Custom Script Extension. We will retrieve the storage account key when the storage account finishes provisioning.

``` console
az storage account create --name <storage_account_name> --resource-group <resource_group_name>
az storage account keys list --account-name <storage_account_name> --resource-group <resource_group_name>
```

As Always, once provisioned, we will export the required environment variables.

``` console
export AZURE_STORAGE_NAME=<storage_account_name>
export AZURE_STORAGE_KEY=<storage_account_key>
```

## Generate Certificates

Now it's time to generate certificates for your deployment. It can be done in a lot of different ways, we just describe one possible approach implemented in this reference architecture.

This reference has a C# .NET Core service that can be leveraged to create signed certificates and upload them to the Azure Key Vault. You can find the source code in `services/CertificateGeneration/` folder. For ease of use in this demo, this folder contains a Dockerfile configured to build and run this service. You can find `build.sh` and `run.sh` scripts, if you don't remember the docker options. By default, it uses port `localhost:5000` address. You can find more info about this service in its [readme.md](../services/CertificateGeneration/README.md).

`run.sh` passes `$AZURE_KEYVAULT_CLIENT_ID` and `$AZURE_KEYVAULT_CLIENT_SECRET` to the service. You can open new terminal window, set these environment variables and run `scripts/start_service.sh`. It will build and run docker image with certificate generation service. You should see similar output in your window.

``` console
Hosting environment: Production
Content root path: /app
Now listening on: http://0.0.0.0:5000
Application started. Press Ctrl+C to shut down.
```

When the service is up and running, you can use it to generate per-host certificates. Here is a set of assumptions made in this reference architecture:

- Public part of root CA is stored as a secret named root-ca
- Public part of intermediate CA is stored as a secret named intermediate-ca
- Certificates name in the keyvault is equal to the host name
    - Host certificate has `"CN=<hostname>"`

We use VM Scale Sets for the deployment, so it leads to a few things that you should be aware of:

- Hostname has a format `vmss_prefix` + `-` + `number`, where `number` starts with `000000` and increments by 1.
- If you deploy VMSS with `X` VMs, you should overprovision certificates because VMSS deploys `X+Y` VMs and then removes `Y` VMs

In our scenario each deployment lifetime is known and limited. As a result, we are not solving certificates rotation and expiration in this sample.

For this sample we use our own self-signed root CA, signed intermediate CA and signed host certificates.
If you use scripts from this sample, you should update `scripts/hostnames.json` file with hostnames of the VMs you're going to provision. The structure of this file is fairly simple, it has a list of hostnames.

``` json
{
    "hosts":[
        "vm-000000",
        "vm-000001"
    ]
}
```

Now you can run `scripts/generate_certificates.py`. This script will perform 3 actions:

- Generate self-signed certificate, used as a root CA and uploads its public part to Azure
- Generate signed intermediate CA certificate and uploads its public part to Azure
- Generates signed certificates for each host, using names from `hostnames.json`

For more details you can reference comments in this script.
When finished, you can stop docker container because we no longer need certificates generation service.

## Deploy The Cluster

This section describes each action from `deploy.sh` script. If you execute it, it will deploy VM Scale Set with required infrastructure, provision MSI and Custom Script extensions. It will grant Key Vault access to the provisioned identity. When its done, VMs will download unique certificates and configure opportunistic IPSec inside the VNET.

Before the deployment, we need to upload content of `vm-files` folder to Azure Storage. There is `scripts/upload_files.py` script, it will pack `vm-files/config` and `vm-files/scripts` folders to the `tar.gz` file. After this, `vm-files.tar.gz` and `bootstrap.sh` are uploaded to Azure Storage.
This script generates SAS tokens to access these files. The output contains shell command to configure `TF_VAR_files` environment variable for terraform deployment. You can use `eval` to execute this command.

``` console
$ python upload_files.py
export TF_VAR_files='["<boostrap.sh>", "<vm-files.tar.gz>"]'

$ eval $(python upload_files.py)
```

Next, we need to configure other terraform variables:

``` console
export TF_VAR_client_id=$AZURE_MGMT_CLIENT_ID
export TF_VAR_client_secret=$AZURE_MGMT_CLIENT_SECRET
export TF_VAR_tenant_id=$AZURE_TENANT_ID
export TF_VAR_subscription_id=$AZURE_SUBSCRIPTION_ID
export TF_VAR_command="bash bootstrap.sh $AZURE_KEY_VAULT_URL"
```

At this moment, terraform is ready for the deployment. Just run these commands and wait.

``` console 
cd <root_folder>/deployment/terraform
terraform init
terraform apply
```

It will take a few minutes to provision VM Scale Set cluster. If succesfully finished, VM Scale Set has scripts that are trying to access Azure Key Vault and configure IPSec. Now you need to grant an access for the provisioned MSI identity to your Azure Key Vault. You can find `VMSS SPN` in terraform output.

You should grant get access for certificates and secrets.

``` console
az keyvault set-policy --name $AZURE_KEY_VAULT_NAME --certificate-permissions get --secret-permissions get --object-id <VMSS_SPN>
```

When finished, VMs will complete IPSec configuration. You can find more details [here](../vm-files/README.md).

## Verify IPSec Status

Finally you can verify IPSec status inside your VNET. To inspect it, you can SSH into one of your VMs.
You can find IP and port in Azure Load Balancer details (by default load balancer uses ports starting with 50000 to route ssh connection to the VM Scale Set hosts).

First, try to ping other VMs inside this VNET. After this you can verify that tunnels were succesfully created.

``` console
$ ping 10.0.0.4
$ sudo ipsec whack --trafficstatus
```

You can run `sudo ipsec status` to verify your current IPSec status.
