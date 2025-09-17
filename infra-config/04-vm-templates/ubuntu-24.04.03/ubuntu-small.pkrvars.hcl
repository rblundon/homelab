##################################################################################
# VARIABLES
##################################################################################

# Virtual Machine Settings

vm_boot_wait    = "5s"
vm_name         = "ubuntu-24.04-small"
vm_id           = "9201"
vm_cpu_sockets  = "1"
vm_cpu_cores    = "2"
vm_mem_size     = "2048"
vm_disk_size    = "8"

proxmox_bridge  = "vmbr0"

ssh_username    = "wed"

# ISO Objects

iso_file             = "ubuntu-24.04.3-live-server-amd64.iso"
iso_checksum         = "c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b"
iso_checksum_type    = "sha256"

# Scripts

#shell_scripts               = ["scripts/cleanup.sh"]
