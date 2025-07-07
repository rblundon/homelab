##################################################################################
# VARIABLES
##################################################################################

# Credentials

proxmox_username   = "root@pam"
proxmox_password   = ""
ssh_username       = "wed"
ssh_password       = ""

# Proxmox Objects
proxmox_node                    = "pve03"
proxmox_domain                  = "int.mk-labs.cloud"
#proxmox_url                     = "https://${var.proxmox_node}.${proxmox_domain}:8006/api2/json"
proxmox_vm_storage_pool         = "pve-templates"
#proxmox_insecure_connection     = false #Default: true
proxmox_iso_storage_pool        = "local"

template_name   = ""
