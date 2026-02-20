#!/usr/bin/env bash

set -euxo pipefail

# Sync NWN2 install directory to NWN2 stage directory
if [[ ! -e "/opt/nwn2-stage/.nwn2-staged" ]]; then
  rsync -avz --chown=nwnx4:nwnx4 --ignore-existing /srv/nwn2/ /opt/nwn2-stage/
  rm -rf /opt/nwn2-stage/Miles
  touch /opt/nwn2-stage/.nwn2-staged
fi

# Create NWNX4 user directory symlinks to NWNX4 install directory
for file in $(ls /srv/nwnx4-user); do
  if [[ ! -e "/opt/nwnx4/$file" ]]; then
    ln -s "/srv/nwnx4-user/$file" /opt/nwnx4/ && chown nwnx4:nwnx4 -h "/opt/nwnx4/$file"
  fi
done

# Copy plugins from NWNX4 user and install directories
rsync -avz --chown=nwnx4:nwnx4 --ignore-existing /srv/nwnx4-user/plugins/*.dll /etc/nwnx4/plugins/
rsync -avz --chown=nwnx4:nwnx4 --ignore-existing /opt/nwnx4/plugins/*.dll /etc/nwnx4/plugins/

# Wine doesn't support NCrypt well; building it here through openssl
CERTIFICATE_PATH="/srv/nwnx4-user/NWNCertificate"
HOSTNAME="CN=Neverwinter Nights"
ALGORITHM="sha384"

if [ ! -e "${CERTIFICATE_PATH}.pfx" ]; then
  # Generate private key
  openssl ecparam -name secp384r1 -genkey -noout -out "${CERTIFICATE_PATH}.key"

  # Generate certificate request
  openssl req -new -key "${CERTIFICATE_PATH}.key" -subj "/${HOSTNAME}" -out "${CERTIFICATE_PATH}.csr"

  # Self-sign certificate
  openssl x509 -req -days 365000 -in "${CERTIFICATE_PATH}.csr" -signkey "${CERTIFICATE_PATH}.key" -sha384 -out "${CERTIFICATE_PATH}.crt" -extfile <(
    echo "[v3_ca]
  basicConstraints = CA:TRUE
  subjectAltName = DNS:${HOSTNAME}"
  )
  openssl x509 -in "${CERTIFICATE_PATH}.crt" -outform DER -out "${CERTIFICATE_PATH}.cer"

  # Combine key and certificate into PKCS12 format
  openssl pkcs12 -export -in "${CERTIFICATE_PATH}.crt" -inkey "${CERTIFICATE_PATH}.key" -out "${CERTIFICATE_PATH}.pfx" -passout pass:

  # Remove certificate request (.csr) and certificate (.crt)
  rm "${CERTIFICATE_PATH}.key"
  rm "${CERTIFICATE_PATH}.csr"
  rm "${CERTIFICATE_PATH}.crt"
fi

# All files in the /srv/nwnx4-user and /srv/nwn2-logs folder must be owned by the nwnx4 user
chown -R nwnx4:nwnx4 /srv/nwnx4-user
chown -R nwnx4:nwnx4 /srv/nwn2-logs

gosu nwnx4 bash <<-EOF
  Xvfb $DISPLAY &
  wine reg import /opt/nwn2.reg
EOF

exec gosu nwnx4 "$@"
