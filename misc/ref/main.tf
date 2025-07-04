terraform {
  required_providers {
    nutanix = {
      source  = "terraform-provider-nutanix/nutanix" # "nutanix/nutanix"
      version = "2.2.0"                              # ">= 1.5.0"
    }
  }
}

provider "nutanix" {
  username = var.nutanix_username # Nutanix Prism username
  password = var.nutanix_password # Nutanix Prism password
  endpoint = var.nutanix_endpoint # Nutanix Prism endpoint (IP or hostname)
  port     = 9440                 # Default Prism port
  insecure = true                 # Skip SSL verification (set to false in production)
}

variable "nutanix_username" { type = string }             # Prism username
variable "nutanix_password" { type = string }             # Prism password
variable "nutanix_endpoint" { type = string }             # Prism endpoint
variable "nutanix_cluster_name" { type = string }         # Name of the Nutanix cluster
variable "nutanix_internet_subnet_name" { type = string } # Name of the internet subnet
variable "nutanix_intranet_subnet_name" { type = string } # Name of the intranet subnet
variable "nutanix_image_name" { type = string }           # Name of the VM image to use

variable "num_clients" { type = number }  # Number of client VMs to create
variable "num_gateways" { type = number } # Number of gateway VMs to create

variable "ssh_username" { type = string } # SSH username for VMs
variable "ssh_password" { type = string } # SSH password for VMs

data "nutanix_cluster" "cluster" {
  name = var.nutanix_cluster_name # Fetch cluster UUID by name
}

data "nutanix_subnet" "internet" {
  subnet_name = var.nutanix_internet_subnet_name # Fetch internet subnet UUID by name
}

data "nutanix_subnet" "intranet" {
  subnet_name = var.nutanix_intranet_subnet_name # Fetch intranet subnet UUID by name
}

data "nutanix_image" "image" {
  image_name = var.nutanix_image_name # Fetch image UUID by name
}

locals {
  cluster_uuid         = data.nutanix_cluster.cluster.metadata.uuid                                    # Cluster UUID
  internet_subnet_uuid = data.nutanix_subnet.internet.metadata.uuid                                    # Internet subnet UUID
  intranet_subnet_uuid = data.nutanix_subnet.intranet.metadata.uuid                                    # Intranet subnet UUID
  image_uuid           = data.nutanix_image.image.metadata.uuid                                        # Image UUID
  client_names         = [for i in range(1, var.num_clients + 1) : "client${i}"]                       # List of client names
  gateway_names        = [for i in range(1, var.num_gateways + 1) : "gateway${i}"]                     # List of gateway names
  client_ips           = { for idx, name in local.client_names : name => "192.168.138.${128 + idx}" }  # Map client name to static IP
  gateway_internet_ips = { for idx, name in local.gateway_names : name => "192.168.138.${140 + idx}" } # Map gateway name to internet IP
  gateway_intranet_ips = { for idx, name in local.gateway_names : name => "192.168.162.${134 + idx}" } # Map gateway name to intranet IP
}

# Create client VMs
resource "nutanix_virtual_machine" "client" {
  for_each             = toset(local.client_names) # One VM per client name
  name                 = each.key                  # VM name
  cluster_uuid         = local.cluster_uuid        # Cluster to deploy to
  num_vcpus_per_socket = 2                         # vCPUs per socket
  num_sockets          = 1                         # Number of sockets
  memory_size_mib      = 512                       # Memory in MiB

  disk_list {
    data_source_reference = {
      kind = "image"
      uuid = local.image_uuid # Use the specified image
    }
    device_properties {
      device_type = "DISK" # Disk type
    }
    disk_size_mib = 8192 # Disk size in MiB
  }

  nic_list {
    subnet_uuid = local.internet_subnet_uuid # Attach to internet subnet
    ip_endpoint_list {
      ip   = local.client_ips[each.key] # Assign static IP
      type = "ASSIGNED"                 # Default type for assigned IPs
    }
  }

  connection {
    type     = "ssh"                      # Connection type
    host     = local.client_ips[each.key] # Use the assigned IP
    user     = var.ssh_username           # SSH user
    password = var.ssh_password           # SSH password
  }

  provisioner "file" {
    source      = "scripts/client_setup.sh" # Path to the setup script
    destination = "/tmp/client_setup.sh"    # Destination path on the VM
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/client_setup.sh", # Make the script executable
      "/tmp/client_setup.sh"           # Execute the setup script
    ]
  }
}

# Create gateway VMs
resource "nutanix_virtual_machine" "gateway" {
  for_each             = toset(local.gateway_names) # One VM per gateway name
  name                 = each.key                   # VM name
  cluster_uuid         = local.cluster_uuid         # Cluster to deploy to
  num_vcpus_per_socket = 2                          # vCPUs per socket
  num_sockets          = 1                          # Number of sockets
  memory_size_mib      = 512                        # Memory in MiB

  disk_list {
    data_source_reference = {
      kind = "image"
      uuid = local.image_uuid # Use the specified image
    }
    device_properties {
      device_type = "DISK" # Disk type
    }
    disk_size_mib = 8192 # Disk size in MiB
  }

  nic_list {
    subnet_uuid = local.internet_subnet_uuid # Attach to internet subnet
    ip_endpoint_list {
      ip   = local.gateway_internet_ips[each.key] # Assign static IP
      type = "ASSIGNED"                           # Default type for assigned IPs
    }
  }
  nic_list {
    subnet_uuid = local.intranet_subnet_uuid # Attach to intranet subnet
    ip_endpoint_list {
      ip   = local.gateway_intranet_ips[each.key] # Assign static IP
      type = "ASSIGNED"                           # Default type for assigned IPs
    }
  }

  connection {
    type     = "ssh"                                # Connection type
    host     = local.gateway_internet_ips[each.key] # Use the assigned internet IP
    user     = var.ssh_username                     # SSH user
    password = var.ssh_password                     # SSH password
  }

  provisioner "file" {
    source      = "scripts/gateway_setup.sh" # Path to the setup script
    destination = "/tmp/gateway_setup.sh"    # Destination path on the VM
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/gateway_setup.sh", # Make the script executable
      "/tmp/gateway_setup.sh"           # Execute the setup script
    ]
  }
}
