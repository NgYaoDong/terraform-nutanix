# Data sources for Nutanix cluster, subnets, and image

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
