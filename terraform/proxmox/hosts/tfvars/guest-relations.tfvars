# ─── guest-relations ───────────────────────────────────────────────────────────────
# Authentik Identity Provider / SSO
# Provisioned manually (pre-pipeline bootstrap — NetBox not yet available)
#
# Apply:
#   cd terraform/proxmox/hosts
#   terraform apply \
#     -var-file="tfvars/guest-relations.tfvars" \
#     -state="states/guest-relations.tfstate"

hostname      = "guest-relations"
vm_id         = 71040
ip_address    = "10.1.71.40"
target_node   = "main-street-usa"
template_name = "ubuntu-24.04-medium"

# Bootstrap mode — no n8n/NetBox pipeline available yet
started  = true
use_dhcp = false
