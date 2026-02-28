# ─── DHCP Static Reservation ─────────────────────────────────────────────────
# Creates a fixed IP assignment on the UDM Pro for the newly provisioned VM.
# Triggered by n8n after Proxmox VM creation returns the MAC address.

resource "unifi_user" "vm" {
  name       = var.hostname
  mac        = lower(var.mac_address)
  fixed_ip   = var.ip_address
  network_id = var.network_id

  note = "Managed by mk-labs pipeline"
}
