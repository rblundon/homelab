# ─── VM ID Convention ────────────────────────────────────────────────────────
# VM ID = {third_octet}{fourth_octet:03d}
# Example: 10.1.71.35 → 71035
# Computed by n8n and passed as a variable to keep the logic in one place.

# ─── Template Lookup ─────────────────────────────────────────────────────────
# Find the template VM ID by name on the clone node

data "proxmox_virtual_environment_vms" "templates" {
  node_name = var.clone_node

  filter {
    name   = "template"
    values = ["true"]
  }

  filter {
    name   = "name"
    values = [var.template_name]
  }
}

# ─── VM Resource ─────────────────────────────────────────────────────────────

resource "proxmox_virtual_environment_vm" "vm" {
  name    = var.hostname
  vm_id   = var.vm_id
  node_name = var.target_node

  description = "Provisioned by mk-labs pipeline on ${timestamp()}"
  tags        = ["managed", "pipeline"]

  # Clone from template on fantasyland
  clone {
    vm_id   = data.proxmox_virtual_environment_vms.templates.vms[0].vm_id
    node_name = var.clone_node
    full      = true
    datastore_id = var.datastore
  }

  # Cloud-init configuration
  # Uses DHCP — Unifi DHCP reservation is created before VM starts
  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    dns {
      servers = var.dns_servers
      domain  = var.search_domain
    }

    datastore_id = var.datastore
  }

  # Network interface
  network_device {
    bridge  = var.bridge
    model   = "virtio"
  }

  # VM stays STOPPED after clone.
  # n8n handles: DHCP reservation → HA affinity rule → VM start
  # This ensures DHCP is in place before first boot.
  started = false

  # QEMU guest agent is installed in template (via Packer).
  # Note: Proxmox 9 requires VM.GuestAgent.Audit privilege on the API token.
  agent {
    enabled = true
  }

  # Prevent Terraform from fighting with manual changes
  lifecycle {
    ignore_changes = [
      description,
      tags,
    ]
  }
}
