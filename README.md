# terraform-nutanix

[![GitHub](https://img.shields.io/badge/GitHub-NgYaoDong%2Fterraform--nutanix-blue?logo=github)](https://github.com/NgYaoDong/terraform-nutanix)

This project automates the deployment of a network of Strongswan VPNs in a Nutanix environment using Terraform. It provisions client and gateway VMs, configures networking, and sets up VPN connectivity.

## Features

- Deploys multiple client and gateway VMs on Nutanix clusters
- Configures static IPs for all VMs
- Sets up Strongswan VPN automatically via provisioning scripts
- Uses custom shell scripts for post-deployment configuration

## Prerequisites

- Nutanix Element endpoint and credentials
- Terraform >= 1.0
- Nutanix Terraform Provider (version 2.2.0 recommended)
- SSH access to VMs

## Usage

1. **Clone the repository**

2. **Set up the CA**

   Follow the instructions in [`scripts/ca/`](scripts/ca/) to set up the CA properly.

3. **Configure variables**

   Create a `terraform.tfvars` file with your Nutanix environment details and desired VM counts.

   Example:

   ```hcl
   nutanix_endpoint = "<your-nutanix-endpoint>"     # Prism Element endpoint
   nutanix_username = "<your-nutanix-username>"     # Prism Element username
   nutanix_password = "<your-nutanix-password>"     # Prism Element password
   nutanix_cluster_name = "strongswan-terraform"    # Name of the Nutanix cluster
   nutanix_internet_subnet_name = "Internet"        # Name of the internet subnet
   nutanix_intranet_subnet_name = "Intranet"        # Name of the intranet subnet
   nutanix_image_name = "strongswan-alpine"         # Name of the VM image to use
   num_clients  = 2                                 # Number of client VMs to create
   num_gateways = 2                                 # Number of gateway VMs to create
   ssh_username = "root"                            # SSH username for client/gateway VMs
   ssh_password = "password"                        # SSH password for client/gateway VMs
   ```

   Edit the `client_ips`, `gateway_internet_ips` and `gateway_intranet_ips` in the [`locals.tf`](locals.tf) file to configure your desired IP address range.

4. **Deployment preparation**

   - The [`setup.sh`](scripts/entity/setup.sh) script in [`scripts/entity`](scripts/entity/) is automatically copied and executed on each VM to configure Strongswan and VPN certificates.
   - Ensure `env.sh` in [`scripts/entity`](scripts/entity/) is configured with the correct environment variables for certificate setup.
  
   Example:

   ```bash
   # Environment variables for setup.sh
   deployment_username="<your-ca-vm-username>"
   ca_vm_ip="<your-ca-vm-endpoint>"

   local_csr_path="/tmp/${HOSTNAME}Req.pem"
   remote_csr_path="/tmp/csr_inbox/${HOSTNAME}Req.pem"

   local_entity_crt_path="/etc/swanctl/x509/${HOSTNAME}Cert.pem"
   remote_entity_crt_path="/tmp/signed/${HOSTNAME}Cert.pem"

   local_ca_crt_path="/etc/swanctl/x509ca/caCert.pem"
   remote_ca_crt_path="/tmp/ca/caCert.pem"

   ssh_key_path="$HOME/.ssh/id_rsa_entity"
   ca_vm_password="<your-ca-vm-password>"
   ```

5. **Initialize and apply Terraform**

   ```bash
   terraform init
   terraform apply
   ```

    Review the plan and confirm to create the resources.

6. **Post-deployment**

   After the VMs are up, you can access their console in Nutanix Prism Element with the username: `root` and password: `password`.

   The Strongswan VPN should be automatically configured based on the scripts provided.

## Variables

See [`variables.tf`](variables.tf) for all configurable variables:

- `nutanix_endpoint`, `nutanix_username`, `nutanix_password`
- `nutanix_cluster_name`, `nutanix_internet_subnet_name`, `nutanix_intranet_subnet_name`, `nutanix_image_name`
- `num_clients`, `num_gateways`
- `ssh_username`, `ssh_password`

## File Structure

- [`providers.tf`](providers.tf) – Provider configuration
- [`data.tf`](data.tf) – Data sources for cluster, subnets, and image
- [`locals.tf`](locals.tf) – Local values for dynamic resource creation
- [`vms.tf`](vms.tf) – VM resource definitions
- [`variables.tf`](variables.tf) – Input variables
- [`terraform.tfvars`](terraform.tfvars) – User-specific variable values
- [`scripts/`](scripts/) – Shell scripts for VM provisioning
  - [`README.md`](scripts/README.md)
  - [`ca/`](scripts/ca/) – Certificate Authority scripts
    - [`ca_csr_watcher.sh`](scripts/ca/ca_csr_watcher.sh)
    - [`genca.sh`](scripts/ca/genca.sh)
  - [`entity/`](scripts/entity/) – Entity (client/gateway) setup scripts
    - [`env.sh`](scripts/entity/env.sh)
    - [`gencerts.sh`](scripts/entity/gencerts.sh)
    - [`setup.sh`](scripts/entity/setup.sh)
- [`misc/`](misc/) – Miscellaneous configuration and reference files
  - [`conf/`](misc/conf/)
    - [`README.md`](misc/conf/README.md)
    - [`client1/swanctl.conf`](misc/conf/client1/swanctl.conf)
    - [`client2/swanctl.conf`](misc/conf/client2/swanctl.conf)
    - [`client3/swanctl.conf`](misc/conf/client3/swanctl.conf)
    - [`gateway1/swanctl.conf`](misc/conf/gateway1/swanctl.conf)
    - [`gateway2/swanctl.conf`](misc/conf/gateway2/swanctl.conf)
  - [`ref/`](misc/ref/)
    - [`main.tf`](misc/ref/main.tf)
    - [`README.md`](misc/ref/README.md)

## Notes

- Sensitive data (passwords, etc.) should not be committed to version control. See [`.gitignore`](.gitignore) for excluded files.
- The [`setup.sh`](scripts/entity/setup.sh) script expects an `env.sh` file with required environment variables.

## References

- See [`scripts/README.md`](scripts/README.md) and [`misc/ref/README.md`](misc/ref/README.md) for more details on scripts and reference materials.
