import requests
import json
import copy
import os
import sys

import logging

logging.basicConfig(level=logging.INFO)

if len(sys.argv) != 2:
    logging.error("Please pass hostnames filename.")

hostnames_json = open(sys.argv[1], "rt").read()

# Expected POST body
body = {
    "RequestsProperties": 
    [
        {
            "CertificateProperties":
            {
                "SubjectName": "",
                "ValidDays": 0,
                "BasicConstraintCertificateAuthority": True,
                "BasicConstraintHasPathLengthConstraint": True,
                "BasicConstraintPathLengthConstraint": 0,
                "BasicConstraintCritical": True,
                "KeyStrength": 0,
                "SerialNumber": 0
            },
            "KeyVaultCertificateName": "",
            "KeyVaultSecretName": ""
        }
    ],
    "VaultBaseUrl": "",
    "IssuerBase64Pfx": ""
}

# Service endpoint
url = "http://localhost:5000/api/certificates"
vault_url = os.getenv("AZURE_KEY_VAULT_URL")

# Retrieve pfx field from the response
def get_pfx_from_response(response):
    return json.loads(response)[0]["pfx"]

SerialNumber = 0
# Customize body for the request
def create_body(SubjectName, ValidDays, 
                BasicConstraintCertificateAuthority, BasicConstraintHasPathLengthConstraint, 
                BasicConstraintPathLengthConstraint, BasicConstraintCritical, 
                KeyStrength, KVCertificateName, KVSecretName, VaultBaseUrl, IssuerBase64Pfx, SerialNumber):
    result = copy.deepcopy(body)
    result["RequestsProperties"][0]["CertificateProperties"]["SubjectName"] = SubjectName
    result["RequestsProperties"][0]["CertificateProperties"]["ValidDays"] = ValidDays
    result["RequestsProperties"][0]["CertificateProperties"]["BasicConstraintCertificateAuthority"] = BasicConstraintCertificateAuthority
    result["RequestsProperties"][0]["CertificateProperties"]["BasicConstraintHasPathLengthConstraint"] = BasicConstraintHasPathLengthConstraint
    result["RequestsProperties"][0]["CertificateProperties"]["BasicConstraintPathLengthConstraint"] = BasicConstraintPathLengthConstraint
    result["RequestsProperties"][0]["CertificateProperties"]["BasicConstraintCritical"] = BasicConstraintCritical
    result["RequestsProperties"][0]["CertificateProperties"]["KeyStrength"] = KeyStrength
    result["RequestsProperties"][0]["CertificateProperties"]["SerialNumber"] = SerialNumber
    result["RequestsProperties"][0]["KeyVaultCertificateName"] = KVCertificateName
    result["RequestsProperties"][0]["KeyVaultSecretName"] = KVSecretName
    result["VaultBaseUrl"] = VaultBaseUrl
    result["IssuerBase64Pfx"] = IssuerBase64Pfx
    return result

logging.info("Generating root CA.")

SerialNumber += 1
# Generate root CA
root_ca = create_body("CN=www.root.com", 100, True, False, 0, True, 2048, "", "root-ca", vault_url, "", SerialNumber)
r = requests.post(url, json=root_ca)
if (r.status_code != 200):
    exit(1)
root_ca_pfx = get_pfx_from_response(r.text)
logging.info("Root CA generated.")

SerialNumber += 1
# Generate intermediate CA
logging.info("Generating intermediate CA...")
intermediate_ca = create_body("CN=www.intermediate.com", 75, True, False, 0, True, 2048, "", "intermediate-ca", vault_url, root_ca_pfx, SerialNumber)
r = requests.post(url, json=intermediate_ca)
if (r.status_code != 200):
    exit(1)
intermediate_ca_pfx = get_pfx_from_response(r.text)
logging.info("Intermediate CA generated.")


# Load hostnames
hosts = json.loads(hostnames_json)["hosts"]
for host in hosts:
    SerialNumber += 1
    # Generate certificates for each host
    logging.info("Generating host certificate: {}".format(host))
    body = create_body("CN=" + host, 50, False, False, 0, True, 2048, host, "", vault_url, intermediate_ca_pfx, SerialNumber)
    r = requests.post(url, json=body)
    if (r.status_code != 200):
        logging.info("Generation failed!")
    logging.info("Certificate generated.")
