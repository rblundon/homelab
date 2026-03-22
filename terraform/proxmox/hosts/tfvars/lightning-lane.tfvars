# ─── lightning-lane ──────────────────────────────────────────────────────────
# Traefik Reverse Proxy / Load Balancer
# Provisioned manually (pre-pipeline bootstrap — NetBox not yet available)
#
# Apply:
#   cd terraform/proxmox/hosts
#   terraform apply \
#     -var-file="tfvars/lightning-lane.tfvars" \
#     -state="states/lightning-lane.tfstate"

hostname      = "lightning-lane"
vm_id         = 71035
ip_address    = "10.1.71.35"
target_node   = "main-street-usa"
template_name = "ubuntu-24.04-small"

# Bootstrap mode — no n8n/NetBox pipeline available yet
started  = true
use_dhcp = false