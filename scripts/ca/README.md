# Certificate Authority (CA) Scripts

This directory contains scripts and utilities for managing the Certificate Authority (CA) used in the strongSwan VPN deployment. The CA is responsible for signing certificate requests from VPN clients and gateways.

## Files

- [`genca.sh`](genca.sh): Script to initialize and manage the CA, including generating the CA private key and certificate.
- [`ca_csr_watcher.sh`](ca_csr_watcher.sh): Watches for incoming certificate signing requests (CSRs) from entities and signs them automatically.

## Usage

1. **Initialize the CA**
   - Run [`genca.sh`](genca.sh) to generate the CA's private key and self-signed certificate if they do not already exist.

2. **Sign Certificate Requests**
   - Use [`ca_csr_watcher.sh`](ca_csr_watcher.sh) to monitor a directory for incoming CSRs and sign them automatically. This script is typically run on the CA VM.

## How to use the `ca_csr_watcher.sh` script

We will set the [`ca_csr_watcher.sh`](ca_csr_watcher.sh) script as a systemd service in the CA VM to keep it polling continuously for new requests, and issue certificates automatically.

To run your script as a systemd service, follow these steps:

1. **Save your script** (e.g., `/usr/local/bin/ca_csr_watcher.sh`) and make it executable:

   ```bash
   sudo cp ca_csr_watcher.sh /usr/local/bin/ca_csr_watcher.sh
   sudo chmod +x /usr/local/bin/ca_csr_watcher.sh
   ```

2. **Create a systemd service file** (e.g., `/etc/systemd/system/ca-csr-watcher.service`):

    ```ini
    [Unit]
    Description=CA CSR Watcher Service
    After=network.target

    [Service]
    Type=simple
    ExecStart=/usr/local/bin/ca_csr_watcher.sh
    Restart=always
    User=<your-ca-vm-username>

    [Install]
    WantedBy=multi-user.target
    ```

3. **Enable and start the service:**

   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable ca-csr-watcher.service
   sudo systemctl start ca-csr-watcher.service
   ```

4. **Check status and logs:**

   ```bash
   sudo systemctl status ca-csr-watcher.service
   journalctl -u ca-csr-watcher.service
   ```

This will keep your script running in the background and restart it if it fails. Adjust the `User=` line if you want to run as a different user.

## Integration

These scripts are called as part of the automated VPN deployment process. Entities (clients/gateways) generate CSRs and upload them to the CA VM, where `ca_csr_watcher.sh` processes and signs them. The signed certificates are then retrieved by the entities for VPN authentication.

## See Also

- [`../entity/README.md`](../entity/README.md): For scripts used by VPN clients and gateways to generate CSRs and interact with the CA.
