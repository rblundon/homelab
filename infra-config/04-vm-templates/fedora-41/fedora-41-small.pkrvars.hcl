##################################################################################
# VARIABLES
##################################################################################

# Virtual Machine Settings

vm_boot_wait    = "5s"
vm_name         = "fedora-41-small"
vm_id           = "9101"
vm_cpu_sockets  = "1"
vm_cpu_cores    = "2"
vm_mem_size     = "2048"
vm_disk_size    = "8"

proxmox_bridge  = "vmbr1"
proxmox_vlan    = "71"

ssh_username    = "wed"

# ISO Objects

iso_file             = "Fedora-Server-netinst-x86_64-41-1.4.iso"
iso_checksum         = "ca03867ab88fbe565b91ae518e6f7f83debe6415234f29ff2cc5634052840ce8"
iso_checksum_type    = "sha256"
# iso_url              = "https://mirror.rackspace.com/centos-stream/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-dvd1.iso"

# Scripts

shell_scripts               = ["scripts/cleanup.sh"]
