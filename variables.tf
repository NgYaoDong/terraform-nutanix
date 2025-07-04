# Variable declarations for Nutanix and VM configuration
variable "nutanix_endpoint" { type = string } # Prism endpoint
variable "nutanix_username" { type = string } # Prism username
variable "nutanix_password" { type = string } # Prism password

variable "nutanix_cluster_name" { type = string }         # Name of the Nutanix cluster
variable "nutanix_internet_subnet_name" { type = string } # Name of the internet subnet
variable "nutanix_intranet_subnet_name" { type = string } # Name of the intranet subnet
variable "nutanix_image_name" { type = string }           # Name of the VM image to use

variable "num_clients" { type = number }  # Number of client VMs to create
variable "num_gateways" { type = number } # Number of gateway VMs to create

variable "ssh_username" { type = string } # SSH username for VMs
variable "ssh_password" { type = string } # SSH password for VMs
