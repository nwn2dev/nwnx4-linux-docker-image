#!/usr/bin/env bash

set -euxo pipefail

sync_folder() {
  local src="$1"
  local dst="$2"

  mkdir -p "$dst"

  for item in "$src"/*; do
    [ -e "$item" ] || continue

    local name
    name=$(basename "$item")

    # Ignore existing files
    if [ -e "$dst/$name" ]; then
      continue
    fi

    # If root .dll or .exe file, copy
    if [[ -f "$item" && ( "$name" == *.dll || "$name" == *.exe ) ]]; then
      cp -an "$item" "$dst/$name"
    else
      ln -s "$item" "$dst/$name"
    fi
  done

  chown nwnx4:nwnx4 -R "$dst"
}

sync_folder /srv/nwn2 /opt/nwn2
rm -rf /opt/nwn2/Miles
sync_folder /home/nwnx4/nwn2 "$WINEPREFIX/drive_c/users/nwnx4/Documents/Neverwinter Nights 2"
sync_folder /srv/nwnx4-user/plugins /etc/nwnx4/plugins
sync_folder /opt/nwnx4/plugins /etc/nwnx4/plugins

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

gosu nwnx4 bash <<-EOF
  Xvfb $DISPLAY &
  wine reg import /opt/nwn2.reg
EOF

exec gosu nwnx4 "$@"
