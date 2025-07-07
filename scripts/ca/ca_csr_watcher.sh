## This script watches a directory for new Certificate Signing Requests (CSRs),
## signs them using a CA key and certificate, and outputs the signed certificates
## to a specified directory. It uses inotifywait to monitor the directory for changes.

#!/bin/bash

CSR_DIR="/tmp/csr_inbox"
SIGNED_DIR="/tmp/signed"
# CA_KEY="/etc/swanctl/private/caKey.pem" # This path to the CA key requires root access
# CA_CERT="/etc/swanctl/x509ca/caCert.pem" # This path to the CA cert requires root access
# Use a temporary path for the CA key and cert to avoid permission issues
CA_KEY="/tmp/ca/caKey.pem"
CA_CERT="/tmp/ca/caCert.pem"

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
    echo "  Processing $csr..."
    # Issue the certificate using the CA key and cert, output to the new cert file
    pki --issue --cacert "$CA_CERT" --cakey "$CA_KEY" \
        --type pkcs10 --in "$csr" \
        --serial 01 --lifetime 1826 --outform pem > "$crt"
    if [ $? -eq 0 ]; then
      echo "    Issued certificate: $crt"
    else
      echo "    Failed to issue certificate for $csr"
    fi
    rm -f "$csr"  # Remove the CSR
    echo "    Removed CSR: $csr"
  done
done