# ─── Provider Authentication ─────────────────────────────────────────────────

variable "unifi_username" {
  type        = string
  description = "Unifi controller username."
  sensitive   = true
}

variable "unifi_password" {
  type        = string
  description = "Unifi controller password."
  sensitive   = true
}

variable "unifi_api_url" {
  type        = string
  description = "Unifi controller API URL (e.g., https://10.1.0.1:443)."
}

# ─── DHCP Reservation ───────────────────────────────────────────────────────

variable "hostname" {
  type        = string
  description = "Hostname for the DHCP reservation. Used as the client name."
}

variable "mac_address" {
  type        = string
  description = "MAC address of the VM network interface (from Terraform Proxmox output)."
}

variable "ip_address" {
  type        = string
  description = "Fixed IP address for the DHCP reservation (without CIDR, e.g., 10.1.71.100)."
}

variable "network_id" {
  type        = string
  description = "Unifi network ID for the DHCP reservation."
  default     = ""
}
