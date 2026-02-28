# ─── Provider Authentication ─────────────────────────────────────────────────

variable "proxmox_api_url" {
  type        = string
  description = "Proxmox API endpoint URL (e.g., https://fantasyland.mk-labs.net:8006)"
}

variable "proxmox_api_token" {
  type        = string
  description = "Proxmox API token in format: user@realm!token-name=token-secret"
  sensitive   = true
}

# ─── VM Identity ─────────────────────────────────────────────────────────────

variable "hostname" {
  type        = string
  description = "VM hostname. Used as the Proxmox VM name and cloud-init hostname."
}

variable "ip_address" {
  type        = string
  description = "Primary IP address for the VM (without CIDR, e.g., 10.1.71.100). Used for VM ID derivation and DHCP reservation."
}

variable "dns_servers" {
  type        = list(string)
  description = "DNS servers for the VM."
  default     = ["10.1.71.102", "10.1.71.1"]
}

variable "search_domain" {
  type        = string
  description = "DNS search domain for the VM."
  default     = "mk-labs.net"
}

# ─── Proxmox Placement ──────────────────────────────────────────────────────

variable "clone_node" {
  type        = string
  description = "Proxmox node where templates live. Cloning always happens here."
  default     = "fantasyland"
}

variable "target_node" {
  type        = string
  description = "Proxmox node for final VM placement. VM is migrated here after clone."
}

variable "datastore" {
  type        = string
  description = "Proxmox storage pool for VM disks."
  default     = "liberty-tree"
}

# ─── Template Selection ─────────────────────────────────────────────────────

variable "template_name" {
  type        = string
  description = "Name of the Proxmox VM template to clone."

  validation {
    condition = contains([
      "ubuntu-24.04-small",
      "ubuntu-24.04-medium",
      "ubuntu-24.04-large",
      "ubuntu-24.04-large-plus",
      "ubuntu-24.04-xlarge",
      "ubuntu-24.04-xlarge-plus",
    ], var.template_name)
    error_message = "template_name must be a valid Ubuntu 24.04 template."
  }
}

# ─── Network ─────────────────────────────────────────────────────────────────

variable "vlan_id" {
  type        = number
  description = "VLAN tag for the VM network interface."
  default     = 71
}

variable "bridge" {
  type        = string
  description = "Proxmox network bridge for the VM."
  default     = "vmbr0"
}
