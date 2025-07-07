#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

# Initialize variables for CA key and certificate paths
key_file="/etc/swanctl/private/caKey.pem"
cert_file="/etc/swanctl/x509ca/caCert.pem"

echo "Begin generation of CA key and certificate..."

# Generate CA private key
echo "Generating CA private key..."
pki --gen --type ed25519 --outform pem > $key_file

# Generate a self signed CA cert
echo "Generating self-signed CA certificate..."
# The lifetime is set to 3652 days (10 years)
pki --self --ca --lifetime 3652 --in $key_file \
           --dn "C=CH, O=strongSwan, CN=strongSwan Root CA" \
           --outform pem > $cert_file

# Print completion message
echo "CA key and certificate generated and copied to x509ca directory."