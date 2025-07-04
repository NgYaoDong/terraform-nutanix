# Local values for cluster, subnets, image, and dynamic lists/maps
locals {
  cluster_uuid         = data.nutanix_cluster.cluster.metadata.uuid # Cluster UUID
  internet_subnet_uuid = data.nutanix_subnet.internet.metadata.uuid # Internet subnet UUID
  intranet_subnet_uuid = data.nutanix_subnet.intranet.metadata.uuid # Intranet subnet UUID
  image_uuid           = data.nutanix_image.image.metadata.uuid     # Image UUID

  client_names  = [for i in range(1, var.num_clients + 1) : "client${i}"]   # List of client names
  gateway_names = [for i in range(1, var.num_gateways + 1) : "gateway${i}"] # List of gateway names

  client_ips           = { for idx, name in local.client_names : name => "192.168.138.${128 + idx}" }  # Map client name to static IP
  gateway_internet_ips = { for idx, name in local.gateway_names : name => "192.168.138.${140 + idx}" } # Map gateway name to internet IP
  gateway_intranet_ips = { for idx, name in local.gateway_names : name => "192.168.162.${134 + idx}" } # Map gateway name to intranet IP
}
