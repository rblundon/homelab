##################################################################################
# VARIABLES
##################################################################################

# Virtual Machine Settings

vm_boot_wait    = "5s"
vm_name         = "fedora-42-small"
vm_id           = "9101"
vm_cpu_sockets  = "1"
vm_cpu_cores    = "2"
vm_mem_size     = "2048"
vm_disk_size    = "8"

proxmox_bridge  = "vmbr0"
#proxmox_vlan    = ""

ssh_username    = "wed"

# ISO Objects

iso_file             = "Fedora-Server-netinst-x86_64-42-1.1.iso"
iso_checksum         = "231f3e0d1dc8f565c01a9f641b3d16c49cae44530074bc2047fe2373a721c82f"
iso_checksum_type    = "sha256"

# Scripts

shell_scripts               = ["scripts/cleanup.sh"]
