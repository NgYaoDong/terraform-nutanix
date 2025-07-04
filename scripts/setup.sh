#!/bin/bash

# Source variables from external file if it exists
if [ -f ./env.sh ]; then
    source ./env.sh
else
    echo "Error: env.sh file not found. Please create env.sh with the required variables before running this script." >&2
    exit 1
fi

# Create ssh key pair for CA VM
ssh-keygen -t rsa -b 4096 -N "" -f "$ssh_key_path" -C "${deployment_username}@${ca_vm_ip}"

# Copy the entity's ssh public key into the CA VM (automated with sshpass)
sshpass -p "$ca_vm_password" ssh-copy-id -i "${ssh_key_path}.pub" "${deployment_username}@${ca_vm_ip}"

# Upload the CSR file using SFTP
sftp -i "$ssh_key_path" "${deployment_username}@${ca_vm_ip}" <<EOF
put $local_csr_path $remote_csr_path
EOF

# Poll for the entity certificate to appear on the CA VM
max_attempts=30
attempt=1
poll_interval=2
while true; do
    sftp -i "$ssh_key_path" "${deployment_username}@${ca_vm_ip}" <<EOF | grep -q "$(basename $remote_entity_crt_path)"
ls $(dirname $remote_entity_crt_path)
EOF
    if [ $? -eq 0 ]; then
        echo "File $remote_entity_crt_path found on CA VM."
        break
    fi
    if [ $attempt -ge $max_attempts ]; then
        echo "Timeout: $remote_entity_crt_path not found after $((max_attempts * poll_interval)) seconds."
        exit 1
    fi
    echo "Waiting for $remote_entity_crt_path to appear on CA VM (attempt $attempt/$max_attempts)..."
    attempt=$((attempt + 1))
    sleep $poll_interval
done

# Download the entity cert and CA cert using SFTP
sftp -i "$ssh_key_path" "${deployment_username}@${ca_vm_ip}" <<EOF
get $remote_entity_crt_path $local_entity_crt_path
get $remote_ca_crt_path $local_ca_crt_path
EOF

# Check if there is more than one network adapter (excluding loopback)
num_adapters=$(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$' | wc -l)
if [ "$num_adapters" -gt 1 ]; then
    echo "More than one network adapter detected ($num_adapters adapters). Setting ROLE=gateway."
    export ROLE=gateway
else
    echo "One or zero network adapters detected. Setting ROLE=client."
    export ROLE=client
fi

# TODO: Get the VPN configuration files from the CA VM


# Load all configuration files
swanctl --load-all

# If this is a client instance, initiate the 'home' child
if [ "$ROLE" = "client" ]; then
  echo "ROLE=client -- initiating home child"
  sleep 3
  swanctl --initiate --child home
else
  echo "ROLE=$ROLE -- skipping initiate"
fi
