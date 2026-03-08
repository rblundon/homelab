# ─── Provider Authentication ─────────────────────────────────────────────────
# Passed via CLI — never stored in tfvars.

variable "proxmox_api_url" {
  type        = string
  description = "Proxmox API endpoint URL (e.g., https://main-street-usa.local.mk-labs.cloud:8006)"
}

variable "proxmox_api_token" {
  type        = string
  description = "Proxmox API token in format: user@realm!token-name=token-secret"
  sensitive   = true
}

# ─── VM Identity ─────────────────────────────────────────────────────────────

variable "vm_id" {
  type        = number
  description = "Proxmox VM ID. Convention: {third_octet}{fourth_octet:03d} (e.g., 10.1.71.35 → 71035)."
}

variable "hostname" {
  type        = string
  description = "VM hostname. Used as the Proxmox VM name and cloud-init hostname."
}

variable "ip_address" {
  type        = string
  description = "Primary IP address for the VM (without CIDR, e.g., 10.1.71.35)."
}

variable "dns_servers" {
  type        = list(string)
  description = "DNS servers for the VM."
  default     = ["10.1.71.1"]
}

variable "search_domain" {
  type        = string
  description = "DNS search domain for the VM."
  default     = "local.mk-labs.cloud"
}

# ─── Proxmox Placement ──────────────────────────────────────────────────────

variable "clone_node" {
  type        = string
  description = "Proxmox node where templates live."
  default     = "fantasyland"
}

variable "target_node" {
  type        = string
  description = "Proxmox node for final VM placement."
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

# ─── Bootstrap Options ───────────────────────────────────────────────────────
# These override pipeline defaults for manual provisioning (pre-NetBox/n8n).

variable "started" {
  type        = bool
  description = "Start VM after creation. Pipeline: false (n8n starts it). Bootstrap: true."
  default     = false
}

variable "use_dhcp" {
  type        = bool
  description = "Use DHCP (pipeline) or static IP (bootstrap)."
  default     = true
}

variable "subnet_mask" {
  type        = number
  description = "Subnet mask in CIDR notation. Only used when use_dhcp = false."
  default     = 24
}

variable "gateway" {
  type        = string
  description = "Default gateway. Only used when use_dhcp = false."
  default     = "10.1.71.1"
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
