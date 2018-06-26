yum install -y expect
yum install -y libreswan
yum install -y wget

wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py

pip install azure-keyvault
pip install pyopenssl

tar -xzf vm-files.tar.gz

export KEYVAULT_URI=$1
export ROOT_CA_NAME=root-ca
export INTERMEDIATE_CA_NAME=intermediate-ca
export CERTIFICATE_NAME=certificate

python scripts/download_certificate.py && bash scripts/configure.sh "${@:2}" &
