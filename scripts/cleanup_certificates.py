import json
from azure.keyvault import KeyVaultClient
from azure.common.credentials import ServicePrincipalCredentials
import os
import logging

logging.basicConfig(level=logging.INFO)

vault_url = os.getenv("AZURE_KEYVAULT_URL")

# Initialize KV client
credentials = ServicePrincipalCredentials(client_id = os.getenv("AZURE_KEYVAULT_CLIENT_ID"),
                                          secret = os.getenv("AZURE_KEYVAULT_CLIENT_SECRET"),
                                          tenant = os.getenv("AZURE_TENANT_ID"))

kvclient = KeyVaultClient(credentials)

#Create list of secrets
secrets = ["root-ca", "intermediate-ca"]

# Load host names
hosts = json.loads(open("hostnames.json", "rt").read())["hosts"]

# Remove all secrets
for secret in secrets:
    try:
        kvclient.delete_secret(vault_url, secret)
    except:
        logging.critical("Failed to remove: {}".format(secret))

# Remove all hosts
for host in hosts:
    try:
        kvclient.delete_certificate(vault_url, host)
    except:
        logging.critical("Failed to remove: {}".format(secret))
