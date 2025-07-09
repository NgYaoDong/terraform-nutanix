#!/bin/bash

## This script generates keys and certificate requests for strongSwan.
## It creates a private key and a certificate signing request (CSR) using the strongSwan
## PKI tool. The generated files are stored in specified directories.

set -e  # Exit immediately if a command exits with a non-zero status

# Initialize paths for key and certificate requests
echo "Begin generation of keys and certificate requests..." >> /tmp/setup.log
key_file="/etc/swanctl/private/${HOSTNAME}Key.pem"
req_file="$local_csr_path"  # Use the local_csr_path variable from env.sh

# Generate private key
echo "  Generating private key..." >> /tmp/setup.log
pki --gen --type ed25519 --outform pem > "$key_file"

# Generate certificate request
echo "  Generating certificate request..." >> /tmp/setup.log
dn="C=CH, O=strongSwan, CN=${HOSTNAME}.strongswan.org"
san="${HOSTNAME}.strongswan.org"
echo "  Using DN: $dn" >> /tmp/setup.log
echo "  Using SAN: $san" >> /tmp/setup.log
pki --req --type priv --in "$key_file" \
    --dn "$dn" --san "$san" --outform pem > "$req_file"

# Print completion message
echo "Key generated in $key_file." >> /tmp/setup.log
echo "Certificate request generated in $req_file." >> /tmp/setup.log
