from keyvault_wrapper import KeyVaultWrapper
import os
import time

vault_uri = os.environ['KEYVAULT_URI']
root_ca_name = os.environ['ROOT_CA_NAME']
intermediate_ca_name = os.environ['INTERMEDIATE_CA_NAME']
certificate_name = os.environ['CERTIFICATE_NAME']
hostname = os.uname()[1]

def load_data():
    kvwrapper = KeyVaultWrapper()

    kvwrapper.get_secret_to_file(vault_uri, root_ca_name, '', root_ca_name + '.pem')
    kvwrapper.get_secret_to_file(vault_uri, intermediate_ca_name, '', intermediate_ca_name + '.pem')

    kvwrapper.get_certificate_and_key_to_file(
        vault_uri = vault_uri,
        cert_name = hostname,
        cert_version = '',
        key_filename = certificate_name + '.key',
        cert_filename = certificate_name + '.pem')

while True:
    try:
        load_data()
    except:
        time.sleep(5)
        continue
    else:
        break