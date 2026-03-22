# ─── imagineering ──────────────────────────────────────────────────────────
# Semaphore Ansible Automation
# Provisioned manually (pre-pipeline bootstrap — NetBox not yet available)
#
# Apply:
#   cd terraform/proxmox/hosts
#   terraform apply \
#     -var-file="tfvars/imagineering.tfvars" \
#     -state="states/imagineering.tfstate"

hostname      = "imagineering"
vm_id         = 71037
ip_address    = "10.1.71.37"
target_node   = "main-street-usa"
clone_node    = "fantasyland"
template_name = "ubuntu-24.04-medium"
datastore     = "liberty-tree"
bridge        = "vmbr0"
dns_servers   = ["10.1.71.1"]
search_domain = "local.mk-labs.cloud"

# Bootstrap mode — no pipeline available yet
started  = true
use_dhcp = false
