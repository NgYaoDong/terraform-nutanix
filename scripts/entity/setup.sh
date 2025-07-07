## This script sets up a strongSwan VPN client or gateway by generating certificates,
## creating SSH keys, and uploading the necessary files to a CA VM.

#!/bin/bash

# Source variables from external file if it exists
if [ -f /tmp/env.sh ]; then
    # Load environment variables from env.sh
    # This file should contain the necessary variables like ca_vm_ip, deployment_username, etc.
    echo "Sourcing environment variables from env.sh..." >> /tmp/setup.log
    # Ensure the script is executable
    chmod +x /tmp/env.sh
    # Source the environment variables
    source /tmp/env.sh
else
    echo "Error: env.sh file not found. Please create env.sh with the required variables before running this script." >> /tmp/setup.log
    exit 1
fi

# Generate the certificate signing request (CSR) and private key
echo "Generating certificate signing request (CSR) and private key..." >> /tmp/setup.log
chmod +x /tmp/gencerts.sh
bash /tmp/gencerts.sh

# Create ssh key pair for CA VM
echo "Creating SSH key pair for CA VM..." >> /tmp/setup.log
ssh-keygen -t rsa -b 4096 -N "" -f "$ssh_key_path" -C "${deployment_username}@${ca_vm_ip}"

# Copy the entity's ssh public key into the CA VM (automated with sshpass)
echo "Copying SSH public key to CA VM..." >> /tmp/setup.log
sshpass -p "$ca_vm_password" ssh-copy-id -i "${ssh_key_path}.pub" "${deployment_username}@${ca_vm_ip}"

# Upload the CSR file using SFTP
echo "Uploading CSR file to CA VM..." >> /tmp/setup.log
sftp -i "$ssh_key_path" "${deployment_username}@${ca_vm_ip}" <<EOF
put $local_csr_path $remote_csr_path
EOF

# Poll for the entity certificate to appear on the CA VM
max_attempts=30
attempt=1
poll_interval=2
echo "Waiting for entity certificate to appear on CA VM..." >> /tmp/setup.log
while true; do
    sftp -i "$ssh_key_path" "${deployment_username}@${ca_vm_ip}" <<EOF | grep -q "$(basename $remote_entity_crt_path)"
ls $(dirname $remote_entity_crt_path)
EOF
    if [ $? -eq 0 ]; then
        echo "  File $remote_entity_crt_path found on CA VM." >> /tmp/setup.log
        break
    fi
    if [ $attempt -ge $max_attempts ]; then
        echo "  Timeout: $remote_entity_crt_path not found after $((max_attempts * poll_interval)) seconds." >> /tmp/setup.log
        exit 1
    fi
    echo "  Waiting for $remote_entity_crt_path to appear on CA VM (attempt $attempt/$max_attempts)..." >> /tmp/setup.log
    attempt=$((attempt + 1))
    sleep $poll_interval
done

# Get the entity cert and CA cert using SFTP
echo "Getting entity certificate and CA certificate from CA VM..." >> /tmp/setup.log
sftp -i "$ssh_key_path" "${deployment_username}@${ca_vm_ip}" <<EOF
get $remote_entity_crt_path $local_entity_crt_path
get $remote_ca_crt_path $local_ca_crt_path
EOF

# Check if there is more than one network adapter (excluding loopback)
# num_adapters=$(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$' | wc -l)
# if [ "$num_adapters" -gt 1 ]; then
#     echo "More than one network adapter detected ($num_adapters adapters). Setting ROLE=gateway." >> /tmp/setup.log
#     export ROLE=gateway
# else
#     echo "One or zero network adapters detected. Setting ROLE=client." >> /tmp/setup.log
#     export ROLE=client
# fi

# TODO: Get the VPN configuration files from the CA VM


# Load all configuration files
swanctl --load-all

# If this is a client instance, initiate the 'home' child
wait_time=2
if [ "$ROLE" = "client" ]; then
  echo "ROLE=client -- initiating home child" >> /tmp/setup.log
  sleep $wait_time
  swanctl --initiate --child home
else
  echo "ROLE=$ROLE -- skipping initiate" >> /tmp/setup.log
fi
