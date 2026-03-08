# ─── Host Provisioning ───────────────────────────────────────────────────────
# Root module that calls the shared VM module.
# Per-host values come from tfvars files.
# Sensitive values come from CLI arguments.
#
# Usage:
#   terraform apply \
#     -var-file="tfvars/lightning-lane.tfvars" \
#     -state="states/lightning-lane.tfstate" \
#     -var="proxmox_api_url=https://main-street-usa.local.mk-labs.cloud:8006" \
#     -var="proxmox_api_token=terraform@pve!automation=<token>"

module "vm" {
  source = "../vm"

  proxmox_api_url   = var.proxmox_api_url
  proxmox_api_token = var.proxmox_api_token

  hostname      = var.hostname
  vm_id         = var.vm_id
  ip_address    = var.ip_address
  target_node   = var.target_node
  clone_node    = var.clone_node
  template_name = var.template_name
  datastore     = var.datastore
  vlan_id       = var.vlan_id
  bridge        = var.bridge
  dns_servers   = var.dns_servers
  search_domain = var.search_domain

  # Bootstrap overrides
  started     = var.started
  use_dhcp    = var.use_dhcp
  subnet_mask = var.subnet_mask
  gateway     = var.gateway
}
