# terraform-nutanix

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

2. **Configure variables**

   Edit `terraform.tfvars` with your Nutanix environment details and desired VM counts.

   Example:

   ```hcl
   nutanix_endpoint = <your-nutanix-endpoint>
   nutanix_username = <your-nutanix-username>
   nutanix_password = <your-nutanix-password>
   nutanix_cluster_name = "strongswan-terraform"
   nutanix_internet_subnet_name = "Internet"
   nutanix_intranet_subnet_name = "Intranet"
   nutanix_image_name = "strongswan-alpine"
   num_clients  = 2
   num_gateways = 2
   ssh_username = "root"
   ssh_password = "password"
   ```

3. **Initialize and apply Terraform**

   ```bash
   terraform init
   terraform apply
   ```

4. **Post-deployment**

   - The `setup.sh` script in `scripts/` is automatically copied and executed on each VM to configure Strongswan and VPN certificates.
   - Ensure `env.sh` in `scripts/` is configured with the correct environment variables for certificate setup.

## Variables

See `variables.tf` for all configurable variables:

- `nutanix_endpoint`, `nutanix_username`, `nutanix_password`
- `nutanix_cluster_name`, `nutanix_internet_subnet_name`, `nutanix_intranet_subnet_name`, `nutanix_image_name`
- `num_clients`, `num_gateways`
- `ssh_username`, `ssh_password`

## File Structure

- `providers.tf` – Provider configuration
- `data.tf` – Data sources for cluster, subnets, and image
- `locals.tf` – Local values for dynamic resource creation
- `vms.tf` – VM resource definitions
- `variables.tf` – Input variables
- `terraform.tfvars` – User-specific variable values
- `scripts/` – Shell scripts for VM provisioning
- `ref/` – Reference scripts and documentation

## Notes

- Sensitive data (passwords, etc.) should not be committed to version control. See `.gitignore` for excluded files.
- The `setup.sh` script expects an `env.sh` file with required environment variables.

## References

- See `scripts/README.md` and `ref/README.md` for more details on scripts and reference materials.
