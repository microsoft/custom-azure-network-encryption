# cd <root>
# python build/build.py

import base64
import os
import tarfile
from azure.storage.blob import BlockBlobService
from azure.storage.blob import BlobPermissions
from datetime import datetime, timedelta

os.chdir("../vm-files/")

expire_delta = timedelta(hours=24)

storage_account_name = os.getenv("AZURE_STORAGE_NAME")
account_key = os.getenv("AZURE_STORAGE_KEY")

container_name = "vm-scripts-files"

vm_files = ["config/ipsec.conf",
            "scripts/download_certificate.py",
            "scripts/keyvault_wrapper.py",
            "scripts/import.exp",
            "scripts/configure.sh"]

# Zip up all files under the vm-files folder
with tarfile.open("vm-files.tar.gz", "w:gz") as tar:
    for f in vm_files:
        tar.add(f)

blob_service = BlockBlobService(account_name=storage_account_name,
                                account_key=account_key)

# Create container. No-action if exists
blob_service.create_container(container_name=container_name)

# Upload files
blob_service.create_blob_from_path(container_name=container_name,
                                   blob_name='vm-files.tar.gz',
                                   file_path='vm-files.tar.gz')

t = blob_service.create_blob_from_path(container_name=container_name,
                                   blob_name='bootstrap.sh',
                                   file_path='bootstrap.sh')

# Calculate expiration time
expire = datetime.utcnow() + expire_delta

# Generate SAS tokens
bootstrap_sas = blob_service.generate_blob_shared_access_signature(container_name, "bootstrap.sh", BlobPermissions.READ, expire)
vm_files_sas = blob_service.generate_blob_shared_access_signature(container_name, "vm-files.tar.gz", BlobPermissions.READ, expire)

# Generate blob urls
bootstrap_path = blob_service.make_blob_url(container_name, "bootstrap.sh", sas_token=bootstrap_sas)
vm_files_path = blob_service.make_blob_url(container_name, "vm-files.tar.gz", sas_token=vm_files_sas)

# Print result for eval operation
print('export TF_VAR_files=\'["' + bootstrap_path + '","' + vm_files_path + '"]\'')