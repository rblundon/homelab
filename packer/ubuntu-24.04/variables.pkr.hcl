# Proxmox variable definitions

variable "proxmox_username" {
  type    = string
  description = "The username for authenticating to Proxmox."
  default = ""
  sensitive = true
}

variable "proxmox_password" {
  type    = string
  description = "The plaintext password for authenticating to Proxmox."
  default = ""
  sensitive = true
}

variable "proxmox_node" {
  type    = string
  description = "The Proxmox node to store the templates on."
  default = ""
}

variable "proxmox_domain" {
  type    = string
  description = "The domain the Proxmox node resizes in."
  default = ""
}

variable "proxmox_insecure_verify" {
  type    = bool
  description = "If true, does not validate the proxmox server's TLS certificate."
  default = true
}

variable "proxmox_vm_storage_pool" {
  type    = string
  description = "The storage pool where the VM will live."
  default = ""
}

# Virtual Machine variables

variable "vm_name" {
  type    = string
  description = "The template vm name"
  default = ""
}

variable "vm_id" {
  type = number
  description = "The ID of virtual machine."
}

variable "vm_cpu_sockets" {
  type = number
  description = "The number of virtual CPUs sockets."
  default = "1"
}

variable "vm_cpu_cores" {
  type = number
  description = "The number of virtual CPUs cores per socket."
  default = "1"
}

variable "vm_mem_size" {
  type = number
  description = "The size for the virtual memory in MB."
}

variable "vm_disk_size" {
  type = number
  description = "The size of the primary virtual disk in GiB."
}

variable "proxmox_bridge" {
  type = string
  description = "The Proxmox bridge the NIC connects to."
}

#variable "proxmox_vlan" {
#  type = number
#  description = "The VLAN the NIC is on."
#}

variable "vm_boot_wait" {
  type = string
  description = "The time to wait before boot (in seconds)."
  default = ""
}

variable "shell_scripts" {
  type = list(string)
  description = "A list of scripts."
  default = []
}

# ISO Objects

variable "proxmox_iso_storage_pool" {
  type    = string
  description = "The storage pool where the ISO is located."
  default = ""
}

variable "iso_url" {
  type    = string
  description = "The url to retrieve the iso image"
  default = ""
  }

variable "iso_file" {
  type = string
  description = "The file name of the guest operating system ISO image installation media."
  default = ""
}

variable "iso_checksum" {
  type    = string
  description = "The checksum of the ISO image."
  default = ""
}

variable "iso_checksum_type" {
  type    = string
  description = "The checksum type of the ISO image. Ex: sha256"
  default = ""
}

# SSH info

variable "ssh_username" {
  type    = string
  description = "The username to use to authenticate over SSH."
  default = ""
  sensitive = true
}

variable "ssh_password" {
  type    = string
  description = "The plaintext password to use to authenticate over SSH."
  default = ""
  sensitive = true
}

variable "ssh_private_key" {
  type    = string
  description = "The private key to use to authenticate over SSH."
  default = ""
  sensitive = true
}