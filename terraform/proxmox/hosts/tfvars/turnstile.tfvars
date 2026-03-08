# ─── turnstile ───────────────────────────────────────────────────────────────
# Authentik Identity Provider / SSO
# Provisioned manually (pre-pipeline bootstrap — NetBox not yet available)
#
# Apply:
#   cd terraform/proxmox/hosts
#   terraform apply \
#     -var-file="tfvars/turnstile.tfvars" \
#     -state="states/turnstile.tfstate" \
#     -var="proxmox_api_url=https://main-street-usa.local.mk-labs.cloud:8006" \
#     -var="proxmox_api_token=terraform@pve!automation=<token>"

hostname      = "turnstile"
vm_id         = 71040
ip_address    = "10.1.71.40"
target_node   = "main-street-usa"
template_name = "ubuntu-24.04-medium"

# Bootstrap mode — no n8n/NetBox pipeline available yet
started  = true
use_dhcp = false
