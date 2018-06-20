cat intermediate-ca.pem root-ca.pem > chain.pem

openssl pkcs12 -export -in certificate.pem -inkey certificate.key -out certificate.p12 -name ${HOSTNAME} -CAfile chain.pem -certfile chain.pem -password pass:""
ipsec initnss
expect scripts/import.exp

sed -e "s/\${certificate}/${HOSTNAME}/" config/ipsec.conf > /etc/ipsec.d/private_ipsec.conf

echo -e $1 > /etc/ipsec.d/policies/private

ipsec restart