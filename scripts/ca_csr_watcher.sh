#!/bin/bash

CSR_DIR="/tmp/csr_inbox"
SIGNED_DIR="/tmp/signed"
CA_KEY="/etc/swanctl/private/caKey.pem"
CA_CERT="/etc/swanctl/x509ca/caCert.pem"

mkdir -p "$CSR_DIR" "$SIGNED_DIR"

echo "Watching $CSR_DIR for new CSR files..."

while true; do
  # Wait for a new file to be created or moved into the directory
  inotifywait -e create -e moved_to "$CSR_DIR" >/dev/null 2>&1

  # Loop through all .pem and .csr files in the CSR directory
  for csr in "$CSR_DIR"/*.pem "$CSR_DIR"/*.csr; do
    [ -e "$csr" ] || continue  # Skip if no matching files
    base=$(basename "$csr")    # Get the filename only (e.g., client1Req.pem or client1Req.csr)
    # Replace 'Req.pem' or 'Req.csr' with 'Cert.pem' for the output cert filename
    if [[ "$base" == *.pem ]]; then
      cert_name="${base/Req.pem/Cert.pem}"
    elif [[ "$base" == *.csr ]]; then
      cert_name="${base/Req.csr/Cert.pem}"
    else
      cert_name="${base/Req/Cert}"
    fi
    crt="$SIGNED_DIR/$cert_name"  # Full path for the signed certificate
    # Always process the CSR, even if a cert with the same name exists (to allow renewal/overwrite)
    echo "  Processing $csr..."
    # Issue the certificate using the CA key and cert, output to the new cert file
    pki --issue --cacert "$CA_CERT" --cakey "$CA_KEY" \
        --type pkcs10 --in "$csr" \
        --serial 01 --lifetime 1826 --outform pem > "$crt"
    if [ $? -eq 0 ]; then
      echo "    Issued certificate: $crt"
      rm -f "$csr"  # Remove the CSR after successful signing
    else
      echo "    Failed to issue certificate for $csr"
    fi
  done
done