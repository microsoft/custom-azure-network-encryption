# VM Files

## bootstrap

`boostrap.sh` is main startup script. It installs all dependencies and kicks off configuration.

List of existing dependencies:

- libreswan: IPSec software
- expect: program that talks with interactive prompts
- wget: used to download pip
- pip: python package manager
- azure-keyvault and pyopenssl python modules

When dependencies are installed, bootstrap will start `download_certificate.py` script and then `configure.sh`.
This happens in the background to unblock VMSS provisioning. Key Vault access is granted when VMSS is fully provisioned.

## download_certificate.py

This script retrieves `root_ca.pem`, `intermediate_ca.pem` with `certificate.pem` and `certificate.pfx` files from the Key Vault.
It uses MSI authentication to access the Key Vault, so there is no need to pass SP secret to the host.
Script runs until it can successfully download required files.

## configure.sh

This script configures libreswan opportunistic IPSec.

First, we need to upload our certificate to the certificates database. You can import p12 file, containing entire certificates chain.
The only challenge here is in `ipsec import <p12_file>` command. It requires you to provide a password, so we use `expect` to handle it without prompting user.

You can find `expect` script in `import.exp` file.

``` console
$ cat intermediate-ca.pem root-ca.pem > chain.pem
$ openssl pkcs12 -export -in certificate.pem -inkey certificate.key -out certificate.p12 -name ${HOSTNAME} -CAfile chain.pem -certfile chain.pem -password pass:""
$ ipsec initnss
$ expect scripts/import.exp
```

When certificate is imported, it's time to update the configuration files.
You can specify your IPSec configuration in `.conf` file stored in `/etc/ipsec.d/`. IP ranges for policies are stored in `/etc/ipsec.d/policies`.

IPSec configuration template is stored in `config/ipsec.conf` file. You are required to replace `${certificate}` with certificate nickname in the database.
By default it is certificate Common Name (hostname in our case).

``` console
$ sed -e "s/\${certificate}/${HOSTNAME}/" config/ipsec.conf > /etc/ipsec.d/private_ipsec.conf

$ echo "10.0.0.0/8" > /etc/ipsec.d/policies/private

```

Now, everything should be ready to start the IPSec service. When started, you can run `ipsec status` and verify that your policy is active.

``` console
$ ipsec restart

$ ipsec status
```

If you can see private policies in `ipsec status` output, this host should be fully configured!
