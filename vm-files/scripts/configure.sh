cat intermediate-ca.pem root-ca.pem > chain.pem
openssl pkcs12 -export -in certificate.pem -inkey certificate.key -out certificate.p12 -name ${HOSTNAME} -CAfile chain.pem -certfile chain.pem -password pass:""
ipsec initnss
script_imported=0

while [ $script_imported == 0 ]; do
 r=$(expect scripts/import.exp)
 echo $r | grep "pk12util: PKCS12 IMPORT SUCCESSFUL"
 if [ $? == 0 ]; then
 script_imported=1
 fi
done

sed -e "s/\${certificate}/${HOSTNAME}/" config/ipsec.conf > /etc/ipsec.d/private_ipsec.conf
for i in $@
do echo $i >> /etc/ipsec.d/policies/private
done
ipsec restart