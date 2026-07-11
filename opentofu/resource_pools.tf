resource "proxmox_virtual_environment_pool" "production" {
  comment = "Managed by Terraform: Production"
  pool_id = "production"
}
