# Client VM resources
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
    source      = "scripts/setup.sh" # Path to the setup script
    destination = "/tmp/setup.sh"    # Destination path on the VM
  }

  provisioner "file" {
    source      = "scripts/gencerts.sh" # Path to the certificate generation script
    destination = "/tmp/gencerts.sh"    # Destination path on the VM
  }

  provisioner "file" {
    source      = "scripts/env.sh" # Environment variables for the script
    destination = "/tmp/env.sh"    # Destination path for environment variables
  }

  provisioner "file" {
    source      = "misc/conf/${each.key}/swanctl.conf" # Path to the specific swanctl configuration file
    destination = "/etc/swanctl/swanctl.conf"          # Destination path on the VM
  }

  provisioner "remote-exec" {
    inline = [
      "export HOSTNAME=${each.key}", # Set the hostname variable
      "export ROLE=client",          # Set the role to client
      "chmod +x /tmp/setup.sh",      # Make the script executable
      "bash /tmp/setup.sh"           # Execute the setup script
    ]
  }
}

# Gateway VM resources
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
    source      = "scripts/setup.sh" # Path to the setup script
    destination = "/tmp/setup.sh"    # Destination path on the VM
  }

  provisioner "file" {
    source      = "scripts/env.sh" # Environment variables for the script
    destination = "/tmp/env.sh"    # Destination path for environment variables
  }

  provisioner "file" {
    source      = "scripts/gencerts.sh" # Path to the certificate generation script
    destination = "/tmp/gencerts.sh"    # Destination path on the VM
  }

  provisioner "file" {
    source      = "misc/conf/${each.key}/swanctl.conf" # Path to the specific swanctl configuration file
    destination = "/etc/swanctl/swanctl.conf"          # Destination path on the VM
  }

  provisioner "remote-exec" {
    inline = [
      "export HOSTNAME=${each.key}", # Set the hostname variable
      "export ROLE=gateway",         # Set the role to gateway
      "chmod +x /tmp/setup.sh",      # Make the script executable
      "bash /tmp/setup.sh"           # Execute the setup script
    ]
  }
}
