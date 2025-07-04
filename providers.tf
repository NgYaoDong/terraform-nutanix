# Provider and Terraform configuration
terraform {
  required_providers {
    nutanix = {
      source  = "terraform-provider-nutanix/nutanix" # Nutanix provider source (default is "nutanix/nutanix")
      version = "2.2.0"                              # Provider version (default is ">= 1.5.0")
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
